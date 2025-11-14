import Vapor
import Fluent
import Mist

// A component to host our global "add" button
struct MistDemoHeader: Mist.Component
{
    let models: [any Mist.Model.Type] = [] // Doesn't watch any models
    let actions: [any Mist.Action] = [AddDemoModelAction()] // Registers the action
    let template: Mist.Template = .file(path: "mistDemo/MistDemoHeader")
}

struct AddDemoModelAction: Mist.Action
{
    let name: String = "AddDemoModelAction"
    
    // This action does not use the ID, so `id` will be nil
    func perform(id: UUID?, on db: Database) async -> ActionResult
    {
        let words =
        [
            "swift", "vapor", "fluent", "leaf", "websocket", "async",
            "database", "server", "client", "model", "view", "controller",
            "route", "middleware", "protocol", "actor", "request", "response"
        ]
        
        let model1 = DemoModel1(text: words.randomElement() ?? "error")
        
        do
        {
            try await model1.save(on: db)
            let model2 = DemoModel2(text: words.randomElement() ?? "error")
            model2.id = model1.id // Link the models
            try await model2.save(on: db)
            
            return .success(message: "New model pair added")
        }
        catch
        {
            return .failure(message: "Failed to create models: \(error.localizedDescription)")
        }
    }
}

