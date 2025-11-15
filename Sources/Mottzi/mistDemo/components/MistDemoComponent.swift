import Vapor
import Fluent
import Mist

struct MistDemoComponent: Mist.InstanceComponent
{
    let models: [any Mist.Model.Type] = [MistDemoModel1.self, MistDemoModel2.self]
    let actions: [any Mist.Action] = [DeleteAction(), RandomizeAction()]
    let template: Mist.Template = .file(path: "mistDemo/MistDemoComponent")
}

struct DeleteAction: Mist.Action
{
    let name: String = "delete"
    
    func perform(id: UUID?, on db: Database) async -> ActionResult
    {
        guard let model1 = try? await MistDemoModel1.find(id, on: db) else { return .failure(message: "Model1 not found") }
        guard let model2 = try? await MistDemoModel2.find(id, on: db) else { return .failure(message: "Model2 not found") }
        guard let _ = try? await model1.delete(on: db) else { return .failure(message: "Failed to delete Model1") }
        guard let _ = try? await model2.delete(on: db) else { return .failure(message: "Failed to delete Model2") }
        
        return .success()
    }
}

struct RandomizeAction: Mist.Action
{
    func perform(id: UUID?, on db: Database) async -> ActionResult
    {
        guard let model1 = try? await MistDemoModel1.find(id, on: db) else { return .failure(message: "Model1 not found") }
        guard let model2 = try? await MistDemoModel2.find(id, on: db) else { return .failure(message: "Model2 not found") }
        
        model1.text = "\(UUID().uuidString.prefix(8))"
        model2.text = "\(UUID().uuidString.prefix(8))"
        
        guard let _ = try? await model1.save(on: db) else { return .failure(message: "Failed to save Model1") }
        guard let _ = try? await model2.save(on: db) else { return .failure(message: "Failed to save Model2") }
        
        return .success(message: "Randomized successfully")
    }
}
