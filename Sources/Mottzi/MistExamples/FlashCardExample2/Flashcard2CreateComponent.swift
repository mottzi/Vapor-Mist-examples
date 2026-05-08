import Vapor
import Fluent
import Mist
import Elementary

struct Flashcard2CreateTemplateContext: Encodable {}

struct Flashcard2CreateComponent: ElementaryInstanceComponent {
    typealias InstanceModel = FlashcardFrontModel
    typealias TemplateContext = Flashcard2CreateTemplateContext

    let models: [any Mist.Model.Type] = []
    let actions: [any Mist.Action] = [FlashcardCreateAction()]

    func allInstances(on db: Database) async throws -> [FlashcardFrontModel] {
        return []
    }

    func makeTemplateContext(from primaryModel: FlashcardFrontModel, state: ComponentState?, on db: Database) async throws -> Flashcard2CreateTemplateContext? {
        return Flashcard2CreateTemplateContext()
    }

    func body(context: Flashcard2CreateTemplateContext) -> some HTML {
        div(.mistComponent("Flashcard2CreateComponent"), .class("mb-4")) {
            button(.mistAction("CreateCardAction"), .class("btn-primary")) {
                "Create Flashcard"
            }
        }
    }
}
