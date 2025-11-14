import Vapor
import Fluent
import Mist

struct MistDemoHeader: Mist.Component
{
    let models: [any Mist.Model.Type] = []
    let actions: [any Mist.Action] = [AddDemoModelAction()]
    let template: Mist.Template = .file(path: "mistDemo/MistDemoHeader")
}

struct AddDemoModelAction: Mist.Action
{
    let name: String = "AddDemoModelAction"
    
    func perform(id: UUID?, on db: Database) async -> ActionResult
    {
        let words =
        [
            "swift", "vapor", "fluent", "leaf", "websocket", "async",
            "database", "server", "client", "model", "view", "controller",
            "route", "middleware", "protocol", "actor", "request", "response"
        ]
        
        let model1 = DemoModel1(text: words.randomElement()!)
        let model2 = DemoModel2(text: words.randomElement()!)
        model2.id = model1.id
        
        do
        {
            try await model1.save(on: db)
            try await model2.save(on: db)
            
            return .success(message: "New model pair added: ('\(model1.text)', '\(model2.text)')")
        }
        catch
        {
            return .failure(message: "Failed to add model pair: \(error.localizedDescription)")
        }
    }
}

