import Mist
import Vapor

typealias MistModelContainer = Mist.ModelContainer

extension Application
{
    func useDeployPanel()
    {
        self.get("deployment")
        { request async throws -> View in
            
            let rowComponents = await DeploymentRow().makeContainer(ofAll: request.db)
            let currentDeployment = try? await Deployment.getCurrent(on: request.db)

            let statusComponent = currentDeployment.map
            {
                var container = MistModelContainer()
                container.add($0, for: "deployment")
                return container
            }

            struct DeploymentPanelContext: Encodable
            {
                let rows: [MistModelContainer]
                let status: MistModelContainer?
            }

            let context = DeploymentPanelContext(
                rows: rowComponents,
                status: statusComponent
            )

            return try await request.view.render("deployment/DeploymentPanel", context)
        }
    }

}
