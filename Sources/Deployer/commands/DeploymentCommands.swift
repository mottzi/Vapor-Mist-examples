import Vapor

struct DeployCommand: AsyncCommand
{
    struct Signature: CommandSignature {}

    let help: String = ">:D Deploys (pull, build, move and restart) Deployer."

    func run(using context: CommandContext, signature: Signature) async throws
    {
        let runningCount = try await Deployment.query(on: context.application.db)
            .filter(\.$status, .equal, "running")
            .filter(\.$startedAt, .greaterThanOrEqual, Date.now.addingTimeInterval(-1800))
            .count()
        
        guard runningCount == 0 else { return context.console.print("⚠️  Deployment rejected: Another deployment is currently in progress.") }
                
        context.console.print("\nStart deploying...")

        let config = Deployment.Configuration(
            productName: "Deployer",
            supervisorJob: "deployer"
        )
        
        let pipeline = Deployment.Pipeline(config: config)
        
        do
        {
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
        catch
        {
            context.console.print("Error deploying: \(error.localizedDescription).\n")
            await Deployment.Pipeline.Manager.shared.endDeployment()
        }
    }
}
