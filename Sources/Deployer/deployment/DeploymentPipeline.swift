import Fluent
import Vapor

extension Deployment {
    struct Configuration {
        var buildConfiguration: String = "debug"
        var productName: String = "Mottzi"
        var supervisorJob: String = "mottzi"
        var workingDirectory: String = "/var/www/mottzi"
    }
}

extension Deployment {
    struct Pipeline {
        static let config = Configuration()

        // Creates and processes a new `Deployment`. After successfull deployment, this will check for previously cancelled deployments and re-runs the latest one found.
        public static func start(message: String?, on app: Application) async {
            await deploy(message: message, on: app)
        }

        // Re-runs an existing `Deployment`.
        private static func resume(existingDeployment: Deployment, on app: Application) async {
            await deploy(existingDeployment: existingDeployment, on: app)
        }

        // Internal recursive deployment pipeline. It can re-process exisiting deployments or create and process new deployments.
        private static func deploy(
            existingDeployment: Deployment? = nil, message: String? = nil, on app: Application
        ) async {
            let canDeploy = await Manager.shared.requestPipeline()

            let deployment: Deployment

            if let existingDeployment {
                deployment = existingDeployment
                deployment.startedAt = .now
                deployment.status = canDeploy ? "running" : "canceled"
            } else {
                deployment = Deployment(
                    status: canDeploy ? "running" : "canceled",
                    message: message ?? ""
                )
            }

            try? await deployment.save(on: app.db)

            guard canDeploy else { return }

            do {
                try await pull()
                try await build()
                try await move(using: app)

                deployment.status = "success"
                deployment.finishedAt = .now
                try? await deployment.save(on: app.db)
                await Deployment.Pipeline.Manager.shared.endDeployment()

                let canceledDeployment = try await Deployment.query(on: app.db)
                    .filter(\.$status, .equal, "canceled")
                    .filter(\.$startedAt, .greaterThan, deployment.startedAt)
                    .sort(\.$startedAt, .descending)
                    .first()

                if let canceledDeployment {
                    await resume(existingDeployment: canceledDeployment, on: app)
                } else {
                    try await deployment.setCurrent(on: app.db)
                    try await restart()
                }
            } catch {
                deployment.status = "failed"
                deployment.finishedAt = .now
                deployment.errorMessage = error.localizedDescription
                try? await deployment.save(on: app.db)
                await Deployment.Pipeline.Manager.shared.endDeployment()
                Logger(label: "Mottzi.Deployment.Pipeline").error("\(error.localizedDescription)")
            }
        }
    }
}

extension Deployment.Pipeline {
    private enum PipelineError: Error, LocalizedError {
        case initiateError(String)
        case executeError(String)

        var errorDescription: String? {
            switch self
            {
            case .initiateError(let message):
                "Pipeline initiate error: \(message)"

            case .executeError(let message):
                "Pipeline execute error: \(message)"
            }
        }
    }

    private static func execute(_ command: String, step: Int) async throws {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["bash", "-c", command]
            process.currentDirectoryURL = URL(fileURLWithPath: config.workingDirectory)

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

    private static func pull() async throws {
        try await execute("git pull", step: 1)
    }

    private static func build() async throws {
        try await execute(
            "swift build -c \(config.buildConfiguration) --product \(config.productName)", step: 2)
    }

    private static func restart() async throws {
        try await execute("supervisorctl restart \(config.supervisorJob)", step: 4)
    }

    private static func move(using app: Application) async throws {
        let eventLoop = app.eventLoopGroup.any()
        let threadPool = app.threadPool

        let buildPathMottzi =
            "\(config.workingDirectory)/.build/\(config.buildConfiguration)/\(config.productName)"
        let deployPathMottzi = "\(config.workingDirectory)/deploy/\(config.productName)"

        let deployDir = "\(config.workingDirectory)/deploy"

        try await threadPool.runIfActive(eventLoop: eventLoop) {
            let fileManager = FileManager.default

            // Create deploy directory if it doesn't exist
            try fileManager.createDirectory(
                atPath: deployDir,
                withIntermediateDirectories: true,
                attributes: nil
            )

            // Move Mottzi
            if fileManager.fileExists(atPath: deployPathMottzi) {
                try fileManager.removeItem(atPath: deployPathMottzi)
            }
            try fileManager.moveItem(atPath: buildPathMottzi, toPath: deployPathMottzi)
        }.get()
    }

    public static func getCommitMessage(of request: Request) -> String? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let bodyString = request.body.string,
            let jsonData = bodyString.data(using: .utf8),
            let payload = try? decoder.decode(Deployment.Webhook.Payload.self, from: jsonData)
        else { return nil }

        return payload.headCommit.message
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
