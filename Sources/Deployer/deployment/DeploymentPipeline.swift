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
        
        // deployment.startedAt = .now  // !
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
            await resume(existing: nextDeployment, on: app)
        }
        else if let nextDeployment
        {
            try await deployment.setCurrent(on: app.db)
            try await restart()
            await resume(existing: nextDeployment, on: app)
        }
        else
        {
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
    func findNextDeployment2(after deployment: Deployment, on app: Application) async throws -> Deployment?
    {
        let cancelledDeployments = try await Deployment.query(on: app.db)
            .filter(\.$status, .equal, "canceled")
            .filter(\.$startedAt, .greaterThan, deployment.startedAt)
            .sort(\.$startedAt, .descending)
            .all()
        
        var cancelledDeploymentByProduct: [ProductName: Deployment] = [:]
        
        for cancelledDeployment in cancelledDeployments
        {
            guard cancelledDeploymentByProduct[cancelledDeployment.productName] == nil else { continue }
            cancelledDeploymentByProduct[cancelledDeployment.productName] = cancelledDeployment
        }
        
        return cancelledDeploymentByProduct[deployment.productName]
        ?? cancelledDeploymentByProduct.values
            .filter({ $0.productName != "Deployer" && $0.productName != deployment.productName })
            .sorted(by: { $0.startedAt ?? .distantPast > $1.startedAt ?? .distantPast })
            .first
        ?? cancelledDeploymentByProduct["Deployer"]
    }
    
    func findNextDeployment(after deployment: Deployment, on app: Application) async throws -> Deployment?
    {
        // 1. Query ALL canceled deployments (Look back in time)
        let cancelledDeployments = try await Deployment.query(on: app.db)
            .filter(\.$status, .equal, "canceled")
        // .filter(\.$startedAt, .greaterThan, deployment.startedAt) <--- REMOVED
            .sort(\.$startedAt, .descending) // Newest first
            .all()
        
        // 2. Group by product (only keep the newest pending version per product)
        var cancelledDeploymentByProduct: [ProductName: Deployment] = [:]
        for cancelledDeployment in cancelledDeployments
        {
            guard cancelledDeploymentByProduct[cancelledDeployment.productName] == nil else { continue }
            cancelledDeploymentByProduct[cancelledDeployment.productName] = cancelledDeployment
        }
        
        // 3. SAFE SELECTION LOGIC
        
        // Priority A: Same Product (MUST be newer than current)
        if let sameProduct = cancelledDeploymentByProduct[deployment.productName],
           let pendingTime = sameProduct.startedAt,
           let currentTime = deployment.startedAt,
           pendingTime > currentTime
        {
            return sameProduct
        }
        
        // Priority B: Different Products (Can be older than current)
        // We filter out the current product (already handled/rejected above) and "Deployer"
        return cancelledDeploymentByProduct.values
            .filter({ $0.productName != "Deployer" && $0.productName != deployment.productName })
            .sorted(by: { $0.startedAt ?? .distantPast > $1.startedAt ?? .distantPast })
            .first
        // Priority C: Deployer Fallback (Lowest Priority)
        ?? cancelledDeploymentByProduct["Deployer"]
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
