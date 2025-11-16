import Vapor
import Fluent

extension Deployment
{
    /// Handles deployment process execution (pull, build, queue check, restart).
    /// Ensures chronological execution by re-running latest canceled commit after successfull deployments.
    struct Pipeline
    {
        /// Creates and processes a new `Deployment`. After successfull deployment, this will check for previously
        /// cancelled deployments and re-runs the latest one found.
        ///
        /// - Parameter message: The commit message of this deployment
        /// - Note: This is called when a valid GitHub pushevent is received.
        public static func start(message: String?, on database: Database) async
        {
            await deploy(message: message, on: database)
        }
        
        /// Re-runs an existing `Deployment`.
        ///
        /// - Parameter deployment: Deployment to re-run
        /// - Note: This is called on the latest cancelled deployment whenever any deployment finishes successfully.
        private static func resume(existingDeployment: Deployment, on database: Database) async
        {
            await deploy(existingDeployment: existingDeployment, on: database)
        }
        
        /// Internal recursive deployment pipeline. It can re-process exisiting deployments or create and process new deployments.
        ///
        /// - Parameters:
        ///   - existingDeployment: Pass a deployment to re-run it.
        ///   - message: Pass a commit message for newly created deployments.
        private static func deploy(existingDeployment: Deployment? = nil, message: String? = nil, on database: Database) async
        {
            let canDeploy = await Manager.shared.requestPipeline()
            
            let deployment: Deployment
            
            if let existingDeployment
            {
                deployment = existingDeployment
                deployment.startedAt = .now
                deployment.status = canDeploy ? "running" : "canceled"
            }
            else
            {
                deployment = Deployment(
                    status: canDeploy ? "running" : "canceled",
                    message: message ?? ""
                )
            }
            
            try? await deployment.save(on: database)
            
            guard canDeploy else { return }
            
            do
            {
                try await pull()
                try await build()
                try await move()
                
                deployment.status = "success"
                deployment.finishedAt = .now
                try? await deployment.save(on: database)
                await Deployment.Pipeline.Manager.shared.endDeployment()
                
                let canceledDeployment = try await Deployment.query(on: database)
                    .filter(\.$status, .equal, "canceled")
                    .filter(\.$startedAt, .greaterThan, deployment.startedAt)
                    .sort(\.$startedAt, .descending)
                    .first()
                
                if let canceledDeployment
                {
                    await resume(existingDeployment: canceledDeployment, on: database)
                }
                else
                {
                    try await deployment.setCurrent(on: database)
                    try await restart()
                }
            }
            catch
            {
                deployment.status = "failed"
                deployment.finishedAt = .now
                try? await deployment.save(on: database)
                await Deployment.Pipeline.Manager.shared.endDeployment()
                Logger(label: "Mottzi.Deployment.Pipeline").error("\(error.localizedDescription)")
            }
        }
    }
}

extension Deployment.Pipeline
{
    private enum PipelineError: Error, LocalizedError
    {
        case initiateError(String)
        case executeError(String)
        
        var errorDescription: String?
        {
            switch self
            {
                case .initiateError(let message):
                    "Pipeline initiate error: \(message)"
                    
                case .executeError(let message):
                    "Pipeline execute error: \(message)"
            }
        }
    }
    
//    private static func execute(_ command: String, step: Int) async throws
//    {
//        let process = Process()
//        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
//        process.arguments = ["bash", "-c", command]
//        process.currentDirectoryURL = URL(fileURLWithPath: "/var/www/mottzi")
//        
//        let outputPipe = Pipe()
//        process.standardOutput = outputPipe
//        process.standardError = outputPipe
//        
//        try process.run()
//        process.waitUntilExit()
//        
//        if process.terminationStatus != 0
//        {
//            let output = try outputPipe.fileHandleForReading.readToEnd()
//            let str = String(data: output ?? Data(), encoding: .utf8)
//            
//            throw PipelineError.executeError("Command failed: '\(command)'\nOutput: '\(str ?? "")'")
//        }
//    }
    
    private static func execute(_ command: String, step: Int) async throws
    {
        try await withCheckedThrowingContinuation()
        { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["bash", "-c", command]
            process.currentDirectoryURL = URL(fileURLWithPath: "/var/www/mottzi")
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            process.terminationHandler =
            { [pipe, process] _ in
                guard process.terminationStatus != 0 else { return continuation.resume(returning: ()) }
                let output = String(data: (try? pipe.fileHandleForReading.readToEnd()) ?? Data(), encoding: .utf8)
                let error = PipelineError.executeError("Execution of '\(command)' failed with output:\n'\(output ?? "")'")
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
    
    private static func pull() async throws
    {
        try await execute("git pull", step: 1)
    }
    
    private static func build() async throws
    {
        try await execute("swift build -c debug", step: 2)
    }
    
    private static func restart() async throws
    {
        try await execute("supervisorctl restart mottzi", step: 4)
    }
    
    private static func move() async throws
    {
        let fileManager = FileManager.default
        let buildPath = "/var/www/mottzi/.build/debug/Mottzi"
        let deployPath = "/var/www/mottzi/deploy/Mottzi"
        
        do
        {
            try fileManager.createDirectory(atPath: "/var/www/mottzi/deploy", withIntermediateDirectories: true)
            
            if fileManager.fileExists(atPath: deployPath)
            {
                try fileManager.removeItem(atPath: deployPath)
            }
            
            try fileManager.moveItem(atPath: buildPath, toPath: deployPath)
        }
        catch
        {
            throw error
        }
    }
    
    public static func getCommitMessage(of request: Request) -> String?
    {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let bodyString = request.body.string,
              let jsonData = bodyString.data(using: .utf8),
              let payload = try? decoder.decode(Deployment.Webhook.Payload.self, from: jsonData)
        else { return nil }
        
        return payload.headCommit.message
    }
}

extension Deployment.Pipeline
{
    actor Manager
    {
        static let shared = Manager()
        private init() {}
        
        private(set) var isDeploying: Bool = false
        
        func requestPipeline() async -> Bool
        {
            guard isDeploying == false else { return false }
            isDeploying = true
            return true
        }
        
        func endDeployment() async
        {
            isDeploying = false
        }
    }
}
