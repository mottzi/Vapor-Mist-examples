import Vapor
import Fluent
import Mist

struct FlashcardHeaderComponent: InstanceComponent {
    
    let models: [any Mist.Model.Type] = []
    
    let actions: [any Mist.Action] = [CreateCardAction()]
    
    let template: Mist.Template = LeafTemplate.file("FlashcardExample/FlashcardHeader")
    
}

struct CreateCardAction: Action {
    
    let name: String = "CreateCardAction"
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        
        let words = [
            "swift", "vapor", "fluent", "leaf", "websocket", "async",
            "database", "server", "client", "model", "view", "controller",
            "route", "middleware", "protocol", "actor", "request", "response"
        ]
        
        do {
            let model1 = FlashcardFrontModel(text: words.randomElement()!)
            try await model1.save(on: app.db)
            
            let model2 = FlashcardBackModel(text: words.randomElement()!)
            model2.id = model1.id
            try await model2.save(on: app.db)
            
            return .success("New flashcard created: ('\(model1.text)', '\(model2.text)')")
        } catch {
            return .failure("Failed to create flashcard: \(error.localizedDescription)")
        }
    }
}
