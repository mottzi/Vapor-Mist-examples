import Vapor
import Fluent
import Mist

// [CHANGED] Conforms to ClientInteractive
struct DeploymentRow: Mist.InstanceComponent, Mist.ClientInteractive
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
    
    // [NEW] Define Client State
    var clientState: [String : any Encodable] {
        ["isExpanded": false]
    }
    
    // [NEW] Define Client Logic
    var clientLogic: [String : String] {
        ["toggleError": "this.isExpanded = !this.isExpanded"]
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
