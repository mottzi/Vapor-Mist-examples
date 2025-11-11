import Vapor
import Fluent
import Mist

struct DeploymentRow: Mist.Component
{
    let models: [any Mist.Model.Type] = [Deployment.self]
    let actions: [any Action] = [DeleteDeploymentAction()]
    let template: TemplateType = .file(path: "deployment/DeploymentRow")
    
    func render(id: UUID, on db: Database, using renderer: ViewRenderer) async -> String?
    {
        guard var deployment = try? await Deployment.find(id, on: db) else { return nil }
        
        deployment
            .checkStale()
            .checkCurrent()
        
        var container = Mist.ModelContainer()
        container.add(deployment, for: "deployment")
        let context = Mist.SingleComponentContext(component: container)
        
        let templateName = switch template {
            case .file(let path): path
            case .inline: name
        }
        guard let buffer = try? await renderer.render(templateName, context).data else { return nil }
        return String(buffer: buffer)
    }
}

struct DeleteDeploymentAction: Mist.Action
{
    let name: String = "delete"
    
    func perform(id: UUID, on db: Database) async -> ActionResult
    {
        guard let deployment = try? await Deployment.find(id, on: db)
        else { return .failure(message: "Deployment not found") }
        
        guard (try? await deployment.delete(on: db)) != nil
        else { return .failure(message: "Failed to delete deployment") }
        
        return .success()
    }

}

