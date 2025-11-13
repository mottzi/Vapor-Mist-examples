import Vapor
import Fluent
import Mist

struct DeploymentRow: Mist.Component
{
    let models: [any Mist.Model.Type] = [Deployment.self]
    let actions: [any Action] = [DeleteDeploymentAction()]
    let template: Template = .file(path: "deployment/DeploymentRow")

    func allModels(on db: Database) async -> [any Mist.Model]?
    {
        return try? await Deployment.query(on: db)
            .sort(\.$startedAt, .descending)
            .all()
    }
}

struct DeleteDeploymentAction: Mist.Action
{
    let name: String = "delete"
    
    func perform(id: UUID?, on db: Database) async -> ActionResult
    {
        guard let deployment = try? await Deployment.find(id, on: db)
        else { return .failure(message: "Deployment not found") }
        
        guard (try? await deployment.delete(on: db)) != nil
        else { return .failure(message: "Failed to delete deployment") }
        
        return .success()
    }

}

