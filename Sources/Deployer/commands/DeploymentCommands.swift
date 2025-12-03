import Vapor

struct DeployCommand: AsyncCommand
{
    struct Signature: CommandSignature {}

    let help: String = "Pulls, builds, moves and restarts Deployer."

    func run(using context: CommandContext, signature: Signature) async throws
    {
        let uri = URI(string: "http://localhost:8081/Deployer/deploy")
    
        let response = try await context.application.client.post(uri) 
        { request in
            request.headers.add(name: "X-Deploy-Secret", value: "4132Muttenz")
        }
    
        context.console.print("Status: \(response.status)")

        // guard let runningCount = try? await Deployment.query(on: context.application.db)
        //     .filter(\.$status, .equal, "running")
        //     .filter(\.$startedAt, .greaterThanOrEqual, Date.now.addingTimeInterval(-1800))
        //     .count()
        // else { return context.console.print("Error: Could not check availability of Deployer!") }
        
        // guard runningCount == 0 else { return context.console.print("Error: Deployer is already running!") }
        
        // context.console.print("\nStart deploying...")
        // let pipeline = Deployment.Pipeline(productName: "Deployer", supervisorJob: "deployer")

        // do
        // {
        //     context.console.print("    #1 Pull Deployer")
        //     try await pipeline.pull()
            
        //     context.console.print("    #2 Build Deployer")
        //     try await pipeline.build()
            
        //     context.console.print("    #3 Move Deployer")
        //     try await pipeline.move(using: context.application)
            
        //     context.console.print("    #4 Restart Deployer")
        //     try await pipeline.restart()
            
        //     context.console.print("Successfully deployed.\n")
        //     await Deployment.Pipeline.Manager.shared.endDeployment()
        // }
        // catch
        // {
        //     context.console.print("Error deploying: \(error.localizedDescription).\n")
        //     await Deployment.Pipeline.Manager.shared.endDeployment()
        // }
    }
}
