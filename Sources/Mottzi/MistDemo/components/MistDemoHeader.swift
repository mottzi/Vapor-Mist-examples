import Vapor
import Fluent
import Mist

struct MistDemoHeader: Mist.InstanceComponent
{
    let models: [any Mist.Model.Type] = []
    let actions: [any Mist.Action] = [AddDemoModelAction()]
    let template: Mist.Template = .file(path: "MistDemo/MistDemoHeader")
}

struct AddDemoModelAction: Mist.Action
{
    let name: String = "AddDemoModelAction"
    
    func perform(id: UUID?, state: inout MistState, on db: Database) async -> ActionResult
    {
        let words =
        [
            "swift", "vapor", "fluent", "leaf", "websocket", "async",
            "database", "server", "client", "model", "view", "controller",
            "route", "middleware", "protocol", "actor", "request", "response"
        ]
        
        do
        {
            let model1 = MistDemoModel1(text: words.randomElement()!)
            try await model1.save(on: db)
            
            let model2 = MistDemoModel2(text: words.randomElement()!)
            model2.id = model1.id
            try await model2.save(on: db)
            
            return .success(message: "New model pair added: ('\(model1.text)', '\(model2.text)')")
        }
        catch
        {
            return .failure(message: "Failed to add model pair: \(error.localizedDescription)")
        }
    }
}

