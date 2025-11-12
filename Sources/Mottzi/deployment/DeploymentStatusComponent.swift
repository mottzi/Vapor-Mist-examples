import Vapor
import Fluent
import Mist

struct DeploymentStatusComponent: QueryComponent
{

    // Static UUID for this singleton component (generated once)
    // This MUST match the mist-id in DeploymentStatus.leaf
    let staticID = UUID(uuidString: "A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D")!
    
    let models: [any Mist.Model.Type] = [Deployment.self]
    let template: Template = .file(path: "deployment/DeploymentStatus")
    
    func queryModel(on db: Database) async -> (any Mist.Model)?
    {
        return try? await Deployment.getCurrent(on: db)
    }
    
}

