import Vapor
import Mist

struct FlipAction: Action {
    
    let name: String = "flip"

    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        
        let isFlipped = state["isFlipped"]?.bool ?? false
        state["isFlipped"] = .bool(!isFlipped)
        
        return .success()
    }
}

struct DeleteAction: Action {
    
    let name: String = "delete"

    func perform(targetID id: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        
        guard let id else {
            return .failure("No target ID provided")
        }

        guard let model1 = try? await FlashcardFrontModel.find(id, on: app.db) else {
            return .failure("CardFront not found for ID: \(id)")
        }
        
        guard let model2 = try? await FlashcardBackModel.find(id, on: app.db) else {
            return .failure("CardBack not found for ID: \(id)")
        }
        
        do {
            try await model1.delete(on: app.db)
            try await model2.delete(on: app.db)
            return .success()
        } catch {
            return .failure("Failed to delete flashcard: \(error.localizedDescription)")
        }
    }
    
}

struct ShuffleTextAction: Action {
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        
        guard let targetID else {
            return .failure("No target ID provided")
        }

        guard let model1 = try? await FlashcardFrontModel.find(targetID, on: app.db) else {
            return .failure("CardFront not found for ID: \(targetID)")
        }
        
        guard let model2 = try? await FlashcardBackModel.find(targetID, on: app.db) else {
            return .failure("CardBack not found for ID: \(targetID)")
        }

        guard let randomPair = flashCardPairs.randomElement() else {
            return .failure("No pairs available")
        }

        model1.text = randomPair.front
        model2.text = randomPair.back

        do {
            try await model1.save(on: app.db)
            try await model2.save(on: app.db)
            return .success()
        } catch {
            return .failure("Failed to save flashcard: \(error.localizedDescription)")
        }
    }
}

let flashCardPairs: [(front: String, back: String)] = [
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
