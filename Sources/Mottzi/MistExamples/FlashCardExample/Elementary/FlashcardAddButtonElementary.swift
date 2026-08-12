import Vapor
import Fluent
import Mist
import Elementary

struct FlashcardAddButtonElementary: InstanceComponent {

    let models: [any Mist.Model.Type] = []
    let actions: [any Mist.Action] = [FlashcardCreateAction()]

    func body(context: ComponentContext) -> some HTML {
        div(.mistComponent(self.name), .class("mb-4")) {
            button(.mistAction("CreateCardAction"), .class("btn-primary")) {
                "Create card"
            }
        }
    }
}
