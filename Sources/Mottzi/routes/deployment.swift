import Vapor
import Mist

// Typealias to avoid shadowing Mist module with Application.Mist
typealias MistModelContainer = Mist.ModelContainer

extension Application
{

    // registers test route for demo purposes: www.mottzi.de/test
    public func initTestRoute()
    {
        self.get("test") { _ in "Test response string: 3" }
    }
    
    // initializes github webhook handling
    func initPushWebhook()
    {
        // github webhook push event handler
        self.push("pushevent")
        { request async in
            // valid request leads to execution of deployment process
            let commitMessage = Deployment.Pipeline.getCommitMessage(inside: request)
            await Deployment.Pipeline.initiateDeployment(message: commitMessage, on: request.db)
        }
    }
    
    // initializes deployment panel
    func initDeployPanel()
    {
        // deployment panel route
        self.get("deployment")
        { request async throws -> View in
            // get all deployments with proper sorting and status marking
            let deployments = try await Deployment.all(on: request.db)
            
            // find current deployment for header display
            let current = try? await Deployment.current(on: request.db)
            
            // build component contexts manually from the already-fetched deployments
            // (to preserve the in-memory status modifications from Deployment.all())
            var componentContainers: [MistModelContainer] = []
            for deployment in deployments
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
            let context = DeploymentPanelContext(components: componentContainers, current: current)
            
            // render the panel template using data context
            return try await request.view.render("deployment/panel", context)
        }
    }

}
