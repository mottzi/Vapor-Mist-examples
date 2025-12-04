import Fluent
import Vapor

extension Deployment
{
    struct Pipeline
    {
        let config: Configuration
        
        init(config: Configuration)
        {
            self.config = config
        }
        
        init(productName: String, supervisorJob: String)
        {
            self.config = Configuration(productName: productName, supervisorJob: supervisorJob)
        }
        
        public func start(with message: String? = nil, on app: Application) async
        {
            await deploy(message: message, on: app)
        }
    }
}

extension Deployment.Pipeline
{
    typealias ProductName = String

    struct Configuration
    {
        var buildConfiguration: String = "debug"
        var workingDirectory: String = "/var/www/mottzi"
        var productName: String
        var supervisorJob: String
    }
}

extension Deployment.Pipeline
{
    private func resume(existing deployment: Deployment, on app: Application) async
    {
        guard await Manager.shared.requestPipeline() else { return }
        
        deployment.startedAt = .now
        deployment.status = "running"
        try? await deployment.save(on: app.db)
        
        do
        {
            try await run(deployment, on: app)
        }
        catch
        {
            await fail(deployment, with: error, on: app)
        }
    }
    
    private func deploy(message: String?, on app: Application) async
    {
        let canDeploy = await Manager.shared.requestPipeline()
        
        let deployment = Deployment(
            productName: config.productName,
            supervisorJob: config.supervisorJob,
            status: canDeploy ? "running" : "canceled",
            message: message ?? ""
        )
        
        try? await deployment.save(on: app.db)
        
        guard canDeploy else { return }
        
        do
        {
            try await run(deployment, on: app)
        }
        catch
        {
            await fail(deployment, with: error, on: app)
        }
    }
}

extension Deployment.Pipeline
{
    private func run(_ deployment: Deployment, on app: Application) async throws
    {
        try await pull()
        try await build()
        try await move(using: app)
        
        deployment.status = "success"
        deployment.finishedAt = .now
        try await deployment.save(on: app.db)
        await Deployment.Pipeline.Manager.shared.endDeployment()
        
        let nextDeployment = try await findNextDeployment(after: deployment, on: app)
                
        if let nextDeployment, nextDeployment.productName == deployment.productName
        {
            // Case 1: Batching (Same Product)
            // Resume next immediately. Do NOT restart service yet (skip intermediate).
            await resume(existing: nextDeployment, on: app)
        }
        else if let nextDeployment
        {
            // Case 2: Context Switch (e.g. Deployer -> Mottzi)
            try await deployment.setCurrent(on: app.db)
            
            // 1. Run the OTHER product first (Recursion)
            // The current process must stay alive to manage this.
            await resume(existing: nextDeployment, on: app)
            
            // 2. NOW Restart self (Deployer)
            // Everything else is done. Now we can die/update.
            try await restart()
        }
        else
        {
            // Case 3: Queue Empty
            try await deployment.setCurrent(on: app.db)
            try await restart()
        }
    }
    
    private func fail(_ deployment: Deployment, with error: Error, on app: Application) async
    {
        deployment.status = "failed"
        deployment.finishedAt = .now
        deployment.errorMessage = error.localizedDescription
        try? await deployment.save(on: app.db)
        await Deployment.Pipeline.Manager.shared.endDeployment()
        Logger(label: "Mottzi.Deployment.Pipeline").error("\(error.localizedDescription)")
    }
}

extension Deployment.Pipeline
{
    func findNextDeployment(after deployment: Deployment, on app: Application) async throws -> Deployment? 
    {
        // 1. Query ALL canceled deployments (Time filter REMOVED to allow cross-product visibility)
        let cancelledDeployments = try await Deployment.query(on: app.db)
            .filter(\.$status, .equal, "canceled")
            .sort(\.$startedAt, .descending) // Strict Newest-First ordering
            .all()
        
        // 2. Group by product (Keep only the single newest candidate per product)
        var candidates: [ProductName: Deployment] = [:]
        for dep in cancelledDeployments {
            if candidates[dep.productName] == nil { candidates[dep.productName] = dep }
        }
        
        // --- SELECTION LOGIC ---

        // Priority 1: Batching (Same Product)
        // STRICT RULE: Must be newer. This prevents d4 -> d3.
        if let sameProduct = candidates[deployment.productName] {
            if let nextStart = sameProduct.startedAt, 
            let currentStart = deployment.startedAt, 
            nextStart > currentStart 
            {
                return sameProduct
            }
        }
        
        // Priority 2: Other Products (High Priority e.g. Mottzi)
        // We explicitly exclude "Deployer" here to keep it deprioritized.
        let otherApp = candidates.values
            .filter { $0.productName != "Deployer" && $0.productName != deployment.productName }
            .sorted { $0.startedAt ?? .distantPast > $1.startedAt ?? .distantPast }
            .first
        
        if let otherApp { return otherApp }

        // Priority 3: Deployer (Low Priority / Context Switch)
        // We only switch to Deployer if we are NOT currently running a newer Deployer version.
        if let deployer = candidates["Deployer"] {
            // If we ARE Deployer, we already checked "Priority 1", so if we are here, 
            // it means the candidate is OLDER. We must reject it.
            if deployment.productName == "Deployer" {
                return nil 
            }
            
            // If we are Mottzi, we can switch to Deployer (even if it's older than Mottzi).
            return deployer
        }

        return nil
    }
}

extension Deployment.Pipeline
{
    private enum PipelineError: Error, LocalizedError
    {
        case initiateError(String)
        case executeError(String)
        case moveError(String)
        case successButBackupRemovalError(String)
        
        var errorDescription: String?
        {
            switch self
            {
                case .initiateError(let message): "Pipeline initiate error: \(message)"
                case .executeError(let message): "Pipeline execute error: \(message)"
                case .moveError(let message): "Pipeline move error: \(message)"
                case .successButBackupRemovalError(let message): "Pipeline error: \(message)"
            }
        }
    }
    
    private func execute(_ command: String) async throws
    {
        try await withCheckedThrowingContinuation()
        { (continuation: CheckedContinuation<Void, Error>) in
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["bash", "-c", command]
            process.currentDirectoryURL = URL(fileURLWithPath: config.workingDirectory)
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            process.terminationHandler =
            { [pipe, process] _ in
                
                guard process.terminationStatus != 0 else { return continuation.resume(returning: ()) }
                let output = String(data: (try? pipe.fileHandleForReading.readToEnd()) ?? Data(), encoding: .utf8)
                let error = PipelineError.executeError("Execution of '\(command)' failed with output:\n\n'\(output ?? "NO OUTPUT" )'")
                return continuation.resume(throwing: error)
            }
            
            do
            {
                try process.run()
            }
            catch
            {
                let error = PipelineError.initiateError("Start of '\(command)' failed with ourput:\n'\(error.localizedDescription)'")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func pull() async throws
    {
        try await execute("git pull")
    }
    
    func build() async throws
    {
        try await execute("swift build -c \(config.buildConfiguration) --product \(config.productName)")
    }
    
    func restart() async throws
    {
        try await execute("supervisorctl restart \(config.supervisorJob)")
    }
    
    func move(using app: Application) async throws
    {
        let eventLoop = app.eventLoopGroup.any()
        let threadPool = app.threadPool
        
        let buildPath = "\(config.workingDirectory)/.build/\(config.buildConfiguration)/\(config.productName)"
        let deployDir = "\(config.workingDirectory)/deploy"
        let deployPath = "\(deployDir)/\(config.productName)"
        let backupPath = "\(deployDir)/\(config.productName).old"
        
        try await threadPool.runIfActive(eventLoop: eventLoop)
        {
            let fileManager = FileManager.default
            try fileManager.createDirectory(atPath: deployDir, withIntermediateDirectories: true)
            
            guard fileManager.fileExists(atPath: buildPath) else { throw PipelineError.moveError("New binary not found at \(buildPath)") }
            
            if fileManager.fileExists(atPath: backupPath) { try fileManager.removeItem(atPath: backupPath) }
            if fileManager.fileExists(atPath: deployPath) { try fileManager.moveItem(atPath: deployPath, toPath: backupPath) }
            
            do
            {
                try fileManager.moveItem(atPath: buildPath, toPath: deployPath)
                if fileManager.fileExists(atPath: backupPath) { try? fileManager.removeItem(atPath: backupPath) }
            }
            catch
            {
                let moveError = error
                
                if fileManager.fileExists(atPath: backupPath)
                {
                    do
                    {
                        if fileManager.fileExists(atPath: deployPath) { try fileManager.removeItem(atPath: deployPath) }
                        try fileManager.moveItem(atPath: backupPath, toPath: deployPath)
                    }
                    catch
                    {
                        let rollbackError = error
                        
                        throw PipelineError.moveError(
                            """
                            Deployment failed: '\(moveError.localizedDescription)'. 
                            Rollback failed: '\(rollbackError.localizedDescription)'.
                            """
                        )
                    }
                }
                
                throw PipelineError.moveError(
                    """
                    Deployment failed: '\(moveError.localizedDescription)'. 
                    Rollback successfull.
                    """
                )
            }
        }.get()
    }
}

extension Deployment.Pipeline
{
    actor Manager
    {
        static let shared = Manager()
        private init() {}
        
        private(set) var isDeploying: Bool = false
        
        func requestPipeline() -> Bool
        {
            guard isDeploying == false else { return false }
            isDeploying = true
            return true
        }
        
        func endDeployment()
        {
            isDeploying = false
        }
    }
}
