import Vapor
import Fluent
import Mist
import Elementary

struct Flashcard2CreateComponent: InstanceComponent {

    let models: [any Mist.Model.Type] = []
    let actions: [any Mist.Action] = [FlashcardCreateAction()]

    func body(context: ComponentContext) -> some HTML {
        div(.mistComponent("Flashcard2CreateComponent"), .class("mb-4")) {
            button(.mistAction("CreateCardAction"), .class("btn-primary")) {
                "Create Flashcard"
            }
        }
    }
}
