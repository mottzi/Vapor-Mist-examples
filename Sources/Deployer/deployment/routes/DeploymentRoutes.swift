import Mist
import Vapor

typealias MistModelContainer = Mist.ModelContainer

extension Application {
    func useDeployPanel() {
        self.get("deployment") { request async throws -> View in

            let componentsContext = await DeploymentRow().makeContext(ofAll: request.db)
            let currentDeployment = try? await Deployment.getCurrent(on: request.db)

            var statusComponent: MistModelContainer?
            if let currentDeployment {
                var container = MistModelContainer()
                container.add(currentDeployment, for: "deployment")
                statusComponent = container
            }

            struct DeploymentPanelContext: Encodable {
                let rows: [MistModelContainer]
                let status: MistModelContainer?
            }

            let context = DeploymentPanelContext(
                rows: componentsContext.components,
                status: statusComponent
            )

            return try await request.view.render("deployment/DeploymentPanel", context)
        }
    }

}
