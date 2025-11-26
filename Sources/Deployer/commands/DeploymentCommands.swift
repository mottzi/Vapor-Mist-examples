import Vapor

struct DeployCommand: AsyncCommand
{
    struct Signature: CommandSignature {}

    let help: String = "Deploys binary of Deployer from build directory to deploy directory"

    func run(using context: CommandContext, signature: Signature) async throws
    {
        context.console.print("\nStart deploying Deployer")

        let pipeline = Deployment.Pipeline(
            config: .init(
                productName: "Deployer",
                supervisorJob: "deployer"
            )
        )
        
        do {
            context.console.print("#1 Move Deployer: build directory -> deploy directory")
            try await pipeline.move(using: context.application)
            
            context.console.print("#2 Restart Deployer")
            try await pipeline.restart()
            
            context.console.print("\nSuccessfully deployed Deployer\n")
        }
        catch {
            context.console.print("Error deploying Deployer: \(error.localizedDescription)\n")
        }
    }
}
