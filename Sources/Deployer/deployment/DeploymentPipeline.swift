import Fluent
import Vapor

extension Deployment
{
    struct Configuration
    {
        var buildConfiguration: String = "debug"
        var productName: String = "Mottzi"
        var supervisorJob: String = "mottzi"
        var workingDirectory: String = "/var/www/mottzi"
    }
}

extension Deployment
{
    struct Pipeline
    {
        var config: Configuration = Configuration()

        public func start(with request: Request) async
        {
            await deploy(message: request.commitMessage, on: request.application)
        }

        private func resume(existingDeployment existing: Deployment, on app: Application) async
        {
            await deploy(existingDeployment: existing, on: app)
        }

        private func deploy(existingDeployment existing: Deployment? = nil, message: String? = nil, on app: Application) async
        {
            let canDeploy = await Manager.shared.requestPipeline()
            let status = canDeploy ? "running" : "canceled"
            
            let deployment = existing.map { 
                $0.startedAt = .now
                $0.status = status
                return $0
            } ?? Deployment(
                status: status,
                message: message ?? ""
            )

            try? await deployment.save(on: app.db)

            guard canDeploy else { return }

            do {
                try await run(deployment: deployment, on: app)
            } catch {
                await fail(deployment: deployment, on: app, error: error)
            }
        }
    }
}

extension Deployment.Pipeline 
{
    private func run(deployment: Deployment, on app: Application) async throws 
    {
        try await pull()
        try await build()
        try await move(using: app)

        deployment.status = "success"
        deployment.finishedAt = .now
        try await deployment.save(on: app.db)
        await Deployment.Pipeline.Manager.shared.endDeployment()

        let canceledDeployment = try await Deployment.query(on: app.db)
            .filter(\.$status, .equal, "canceled")
            .filter(\.$startedAt, .greaterThan, deployment.startedAt)
            .sort(\.$startedAt, .descending)
            .first()

        if let canceledDeployment
        {
            await resume(existingDeployment: canceledDeployment, on: app)
        } else {
            try await deployment.setCurrent(on: app.db)
            try await restart()
        }
    }

    private func fail(deployment: Deployment, on app: Application, error: Error) async 
    {
        deployment.status = "failed"
        deployment.finishedAt = .now
        deployment.errorMessage = error.localizedDescription
        try? await deployment.save(on: app.db)
        await Deployment.Pipeline.Manager.shared.endDeployment()
        Logger(label: "Mottzi.Deployment.Pipeline").error("\(error.localizedDescription)")
    }
}

extension Deployment.Pipeline {
    private enum PipelineError: Error, LocalizedError {
        case initiateError(String)
        case executeError(String)
        case moveError(String)
        case successButBackupRemovalError(String)

        var errorDescription: String? {
            switch self
            {
                case .initiateError(let message): "Pipeline initiate error: \(message)"
                case .executeError(let message): "Pipeline execute error: \(message)"
                case .moveError(let message): "Pipeline move error: \(message)"
                case .successButBackupRemovalError(let message): "Pipeline error: \(message)"
            }
        }
    }

    private func execute(_ command: String) async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["bash", "-c", command]
            process.currentDirectoryURL = URL(fileURLWithPath: config.workingDirectory)
            
            var env = ProcessInfo.processInfo.environment
            if env["HOME"] == nil {
                env["HOME"] = "/root"
            }
            if let path = env["PATH"] {
                env["PATH"] = path + ":/usr/local/bin:/usr/bin:/bin"
            } else {
                env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            }
            process.environment = env

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler =
            { [pipe, process] _ in
                guard process.terminationStatus != 0 else {
                    return continuation.resume(returning: ())
                }
                let output = String(
                    data: (try? pipe.fileHandleForReading.readToEnd()) ?? Data(),
                    encoding: .utf8)
                let error = PipelineError.executeError(
                    "Execution of '\(command)' failed with output:\n\n'\(output ?? "NO OUTPUT" )'"
                )
                return continuation.resume(throwing: error)
            }

            do {
                try process.run()
            } catch {
                let error = PipelineError.initiateError(
                    "Start of '\(command)' failed with ourput:\n'\(error.localizedDescription)'")
                continuation.resume(throwing: error)
            }
        }
    }

    func pull() async throws {
        try await execute("git pull")
    }

    func build() async throws {
        try await execute("swift build -c \(config.buildConfiguration)")
    }

    func restart() async throws {
        try await execute("supervisorctl restart \(config.supervisorJob)")
    }

    func move(using app: Application) async throws {
        let eventLoop = app.eventLoopGroup.any()
        let threadPool = app.threadPool
        
        let buildPath = "\(config.workingDirectory)/.build/\(config.buildConfiguration)/\(config.productName)"
        let deployDir = "\(config.workingDirectory)/deploy"
        let deployPath = "\(deployDir)/\(config.productName)"
        let backupPath = "\(deployDir)/\(config.productName).old"
        
        try await threadPool.runIfActive(eventLoop: eventLoop) {
            let fileManager = FileManager.default
            
            try fileManager.createDirectory(atPath: deployDir, withIntermediateDirectories: true)
            
            // new build exists
            guard fileManager.fileExists(atPath: buildPath) else {
                throw PipelineError.moveError("New binary not found at \(buildPath)")
            }
            
            // remove backup
            if fileManager.fileExists(atPath: backupPath) {
                try fileManager.removeItem(atPath: backupPath)
            }
            
            // backup old build 
            if fileManager.fileExists(atPath: deployPath) {
                try fileManager.moveItem(atPath: deployPath, toPath: backupPath)
            }
            
            do {
                // move new build to old build location
                try fileManager.moveItem(atPath: buildPath, toPath: deployPath)
                
                // remove backup
                if fileManager.fileExists(atPath: backupPath) {
                    try? fileManager.removeItem(atPath: backupPath)
                }
            } catch {
                let moveError = error
                // ERROR!
                // if we have a backup -> attempt ROLLBACK
                if fileManager.fileExists(atPath: backupPath) {
                    do {
                        // remove old build
                        if fileManager.fileExists(atPath: deployPath) {
                            try fileManager.removeItem(atPath: deployPath)
                        }
                        // replace old build with backup
                        try fileManager.moveItem(atPath: backupPath, toPath: deployPath)
                    } catch {
                        let rollbackError = error
                        // if rollback fails:
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

extension Deployment.Pipeline {
    actor Manager {
        static let shared = Manager()
        private init() {}

        private(set) var isDeploying: Bool = false

        func requestPipeline() async -> Bool {
            guard isDeploying == false else { return false }
            isDeploying = true
            return true
        }

        func endDeployment() async {
            isDeploying = false
        }
    }
}
