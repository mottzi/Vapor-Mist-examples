import Vapor
import Mist
This will fail due to swift syntax error
typealias MistModelContainer = Mist.ModelContainer

extension Application
{
    func useTestRoute()
    {
        self.get("test") { _ in "Test response 8" }
    }
    
    func useDeployPanel()
    {
        self.get("deployment")
        { request async throws -> View in
            
            let componentsContext = await DeploymentRow().makeContext(ofAll: request.db)
            let currentDeployment = try? await Deployment.getCurrent(on: request.db)
            
            // Build the status component context (matching Mist's structure)
            var statusComponent: MistModelContainer?
            
            if let currentDeployment {
                var container = MistModelContainer()
                container.add(currentDeployment, for: "deployment")
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
