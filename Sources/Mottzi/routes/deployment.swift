import Vapor
import Mist

typealias MistModelContainer = Mist.ModelContainer

extension Application
{
    public func initTestRoute()
    {
        self.get("test") { _ in "Test response string: 7" }
    }
    
    func initPushWebhook()
    {
        self.push("pushevent")
        { request async in
            let commitMessage = Deployment.Pipeline.getCommitMessage(inside: request)
            await Deployment.Pipeline.initiateDeployment(message: commitMessage, on: request.db)
        }
    }
    
    func initDeployPanel()
    {
        self.get("deployment")
        { request async throws -> View in
            
            let componentsContext = await DeploymentRow().makeContext(ofAll: request.db)
            let currentDeployment = try? await Deployment.getCurrent(on: request.db)
            
            // Build the status component context (matching Mist's structure)
            var statusComponent: MistModelContainer?
            if let deployment = currentDeployment {
                var container = MistModelContainer()
                container.add(deployment, for: "deployment")
                statusComponent = container
            }
        
            struct DeploymentPanelContext: Encodable
            {
                let components: [MistModelContainer]
                let component: MistModelContainer?
            }
            
            let context = DeploymentPanelContext(
                components: componentsContext.components,
                component: statusComponent
            )
            
            return try await request.view.render("deployment/DeploymentPanel", context)
        }
    }

}
