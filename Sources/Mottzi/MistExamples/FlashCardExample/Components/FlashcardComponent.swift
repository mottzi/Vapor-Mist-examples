import Fluent
import Mist
import Vapor

struct FlashcardComponent: InstanceComponent {
    
    let models: [any Mist.Model.Type] = [FlashcardFrontModel.self, FlashcardBackModel.self]
    
    let actions: [any Mist.Action] = [DeleteAction(), ShuffleTextAction()]
    
    let template: Mist.Template = LeafTemplate.file("FlashcardExample/FlashcardComponent")
    
}

struct DeleteAction: Mist.Action {
    
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

        let words: Set<String> = [
            "Apple", "Banana", "Orange", "Mango", "Pineapple", "Strawberry", "Blueberry", "Raspberry",
            "Dog", "Cat", "Bird", "Fish", "Rabbit", "Turtle", "Hamster", "Guinea Pig",
            "Red", "Green", "Blue", "Yellow", "Purple", "Orange", "Black", "White",
            "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight",
            "Happy", "Sad", "Angry", "Excited", "Nervous", "Calm", "Bored", "Tired",
        ]

        model1.text = words.shuffled().prefix(1).joined(separator: " ")
        model2.text = words.shuffled().prefix(1).joined(separator: " ")

        do {
            try await model1.save(on: app.db)
            try await model2.save(on: app.db)
            return .success()
        } catch {
            return .failure("Failed to save flashcard: \(error.localizedDescription)")
        }
    }
}

