import Vapor

struct DeployCommand: AsyncCommand
{
    struct Signature: CommandSignature {}

    let help: String = ">:D Deploys (pull, build, move and restart) Deployer."

    func run(using context: CommandContext, signature: Signature) async throws
    {
        // wont work!!!! vapor commands are different processes
        guard await Deployment.Pipeline.Manager.shared.requestPipeline() else {
            context.console.print("⚠️  Deployment rejected: Another deployment is currently in progress.")
            return
        }
        
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
            await Deployment.Pipeline.Manager.shared.endDeployment()
        }
        catch {
            context.console.print("Error deploying: \(error.localizedDescription).\n")
            await Deployment.Pipeline.Manager.shared.endDeployment()
        }
    }
}
