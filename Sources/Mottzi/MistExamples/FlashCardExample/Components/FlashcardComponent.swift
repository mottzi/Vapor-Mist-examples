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
        
        guard let model1 = try? await FlashcardFrontModel.find(id, on: app.db) else {
            return .failure("CardFront not found")
        }
        
        guard let model2 = try? await FlashcardBackModel.find(id, on: app.db) else {
            return .failure("CardBack not found")
        }
        
        guard (try? await model1.delete(on: app.db)) != nil else {
            return .failure("Failed to delete CardFront")
        }
        
        guard (try? await model2.delete(on: app.db)) != nil else {
            return .failure("Failed to delete CardBack")
        }

        return .success()
    }
    
}

struct ShuffleTextAction: Action {
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        
        guard let model1 = try? await FlashcardFrontModel.find(targetID, on: app.db) else {
            return .failure("CardFront not found")
        }
        
        guard let model2 = try? await FlashcardBackModel.find(targetID, on: app.db) else {
            return .failure("CardBack not found")
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

        guard (try? await model1.save(on: app.db)) != nil else {
            return .failure("Failed to save CardFront")
        }

        guard (try? await model2.save(on: app.db)) != nil else {
            return .failure("Failed to save CardBack")
        }

        return .success()
    }
}
