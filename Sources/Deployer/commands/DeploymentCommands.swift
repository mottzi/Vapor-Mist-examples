import Vapor

struct DeployCommand: AsyncCommand
{
    struct Signature: CommandSignature {}
    
    let help: String = "Deploys the deployer itself."
    
    func run(using context: CommandContext, signature: Signature) async throws
    {
        context.console.print("Hello, world!")
        
        let config = Deployment.Configuration(productName: "Deployer", supervisorJob: "deployer")
        
        // git pull
        // swift build
        // move
        // restart
    }
}
