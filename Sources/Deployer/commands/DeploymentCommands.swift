import Vapor

struct DeployCommand: AsyncCommand
{
    struct Signature: CommandSignature {}

    let help: String = "Deploys the deployer itself."

    func run(using context: CommandContext, signature: Signature) async throws
    {
        context.console.print("Starting deployment pipeline to update the deployer...")

        let pipeline = Deployment.Pipeline(
            config: .init(
                productName: "Deployer",
                supervisorJob: "deployer"
            )
        )

        context.console.print("1. git pull")
        try await pipeline.pull()
        
        context.console.print("2. swift build")
        try await pipeline.build()
        
        context.console.print("3. move")
        try await pipeline.move(using: context.application)
        
        context.console.print("4. restart")
        try await pipeline.restart()
    }
}
