import Vapor
import Fluent
import Mist

struct FlashcardLeaf: InstanceComponent {
    
    let models: [any Mist.Model.Type] = [FlashcardFrontModel.self, FlashcardBackModel.self]
    
    let actions: [any Mist.Action] = [DeleteAction(), ShuffleTextAction(), FlipAction()]
    
    let template: Mist.Template = LeafTemplate.file("FlashcardExample/FlashcardLeaf")
    
}
