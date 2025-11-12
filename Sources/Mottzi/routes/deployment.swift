import Vapor
import Mist

typealias MistModelContainer = Mist.ModelContainer

extension Application
{
    public func initTestRoute()
    {
        self.get("test") { _ in "Test response string: 10" }
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
            
            struct DeploymentPanelContext: Encodable
            {
                let components: [MistModelContainer]
                let current: Deployment?
            }
            
            let context = DeploymentPanelContext(
                components: componentsContext.components,
                current: currentDeployment
            )
            
            return try await request.view.render("deployment/DeploymentPanel", context)
        }
    }

}
