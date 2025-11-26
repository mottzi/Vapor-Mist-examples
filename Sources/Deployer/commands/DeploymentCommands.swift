import Vapor

struct DeployCommand: AsyncCommand
{
    struct Signature: CommandSignature {}

    let help: String = "Deploys the deployer itself. :)"

    func run(using context: CommandContext, signature: Signature) async throws
    {
        context.console.print("Starting deployment pipeline to update the deployer...")

        Task.detached 
        {
            let pipeline = Deployment.Pipeline(
                config: .init(
                    productName: "Deployer",
                    supervisorJob: "deployer"
                )
            )

            try await pipeline.move(using: context.application)
            try await pipeline.restart()
        }
    } //
}
