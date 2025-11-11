import Vapor
import Mist

typealias MistModelContainer = Mist.ModelContainer

extension Application
{
    public func initTestRoute()
    {
        self.get("test") { _ in "Test response string: 3" }
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

            let allDeployments = try await Deployment.all(on: request.db)
            let currentDeployment = try? await Deployment.getCurrent(on: request.db)
            
            // build component contexts manually from the already-fetched deployments
            // (to preserve the in-memory status modifications from Deployment.all())
            var componentContainers: [MistModelContainer] = []
            for deployment in allDeployments
            {
                var container = MistModelContainer()
                container.add(deployment, for: "deployment")
                componentContainers.append(container)
            }
            
            struct DeploymentPanelContext: Encodable
            {
                let components: [MistModelContainer]
                let current: Deployment?
            }
            
            // create encoded data context for templating
            let context = DeploymentPanelContext(components: componentContainers, current: currentDeployment)
            
            // render the panel template using data context
            return try await request.view.render("deployment/panel", context)
        }
    }

}
