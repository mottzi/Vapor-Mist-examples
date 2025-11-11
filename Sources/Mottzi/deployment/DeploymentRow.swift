import Vapor
import Fluent
import Mist

struct DeploymentRow: Mist.Component
{

    let models: [any Mist.Model.Type] = [Deployment.self]
    let actions: [any Action] = [DeleteDeploymentAction()]
    let template: TemplateType = .file(path: "deployment/DeploymentRow")
    
    // Override render to apply status marking transformations
    func render(id: UUID, on db: Database, using renderer: ViewRenderer) async -> String?
    {
        // Fetch the deployment
        guard var deployment = try? await Deployment.find(id, on: db) else { return nil }
        
        // Apply the same transformations used in Deployment.all()
        deployment = applyStatusTransformations(to: deployment)
        
        // Build context with transformed deployment
        var container = Mist.ModelContainer()
        container.add(deployment, for: "deployment")
        let context = Mist.SingleComponentContext(component: container)
        
        // Render template
        let templateName = switch template {
            case .file(let path): path
            case .inline: name
        }
        guard let buffer = try? await renderer.render(templateName, context).data else { return nil }
        return String(buffer: buffer)
    }
    
    private func applyStatusTransformations(to deployment: Deployment) -> Deployment
    {
        // Mark stale deployments
        if deployment.status == "running",
           let startedAt = deployment.startedAt,
           Date().timeIntervalSince(startedAt) > 1800
        {
            deployment.status = "stale"
        }
        
        // Mark current deployment as deployed
        if deployment.isCurrent {
            deployment.status = "deployed"
        }
        
        return deployment
    }

}

struct DeleteDeploymentAction: Mist.Action
{

    let name: String = "delete"
    
    func perform(id: UUID, on db: Database) async -> ActionResult
    {
        guard let deployment = try? await Deployment.find(id, on: db) else { return .failure(message: "Deployment not found") }
        guard (try? await deployment.delete(on: db)) != nil else { return .failure(message: "Failed to delete deployment") }
        
        return .success()
    }

}

