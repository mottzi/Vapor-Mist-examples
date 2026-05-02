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
        
        let pairs: [(front: String, back: String)] = [
            ("Hello", "Hola"),
            ("Apple", "Manzana"),
            ("Dog", "Perro"),
            ("Cat", "Gato"),
            ("Book", "Libro"),
            ("Water", "Agua"),
            ("Sun", "Sol"),
            ("Moon", "Luna"),
            ("Friend", "Amigo"),
            ("Thank you", "Gracias"),
            ("Please", "Por favor"),
            ("Good morning", "Buenos días"),
            ("Good night", "Buenas noches"),
            ("How are you?", "¿Cómo estás?"),
            ("I love you", "Te amo"),
            ("Bread", "Pan"),
            ("Coffee", "Café"),
            ("House", "Casa"),
            ("Street", "Calle"),
            ("City", "Ciudad")
        ]
        
        guard let randomPair = pairs.randomElement() else {
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
