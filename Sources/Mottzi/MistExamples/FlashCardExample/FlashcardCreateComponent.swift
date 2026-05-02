import Vapor
import Fluent
import Mist

struct FlashcardCreateComponent: InstanceComponent {
    
    let models: [any Mist.Model.Type] = []
    
    let actions: [any Mist.Action] = [FlashcardCreateAction()]
    
    let template: Mist.Template = LeafTemplate.file("FlashcardExample/FlashcardCreateComponent")
    
}

struct FlashcardCreateAction: Action {
    
    let name: String = "CreateCardAction"
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        
        guard let randomPair = flashCardPairs.randomElement() else {
            return .failure("No pairs available")
        }
        
        do {
            let model1 = FlashcardFrontModel(text: randomPair.front)
            try await model1.save(on: app.db)
            
            let model2 = FlashcardBackModel(text: randomPair.back)
            model2.id = model1.id
            try await model2.save(on: app.db)
            
            return .success("New flashcard created: ('\(model1.text)', '\(model2.text)')")
        } catch {
            return .failure("Failed to create flashcard: \(error.localizedDescription)")
        }
    }
}
