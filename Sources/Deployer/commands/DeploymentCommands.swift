import Vapor

struct DeployCommand: AsyncCommand
{
    struct Signature: CommandSignature {}

    let help: String = "Deploys (pull, build, move and restart) Deployer."

    func run(using context: CommandContext, signature: Signature) async throws
    {
        context.console.print("\nStart deploying...")

        let pipeline = Deployment.Pipeline(
            config: .init(
                productName: "Deployer",
                supervisorJob: "deployer"
            )
        )
        
        do {
            context.console.print("    #1 Pull Deployer")
            try await pipeline.pull()
            
            context.console.print("    #2 Build Deployer")
            try await pipeline.build()
            
            context.console.print("    #3 Move Deployer")
            try await pipeline.move(using: context.application)
            
            context.console.print("    #4 Restart Deployer")
            try await pipeline.restart()
            
            context.console.print("Successfully deployed.\n")
        }
        catch {
            context.console.print("Error deploying: \(error.localizedDescription).\n")
        }
    }
}
