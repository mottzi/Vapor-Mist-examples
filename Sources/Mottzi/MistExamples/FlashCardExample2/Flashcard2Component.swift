import Vapor
import Fluent
import Mist
import Elementary

struct Flashcard2TemplateContext: Encodable {
    let front: FlashcardFrontModel
    let back: FlashcardBackModel
    let isFlipped: Bool
}

public extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
    static func onclick(_ value: String) -> HTMLAttribute {
        HTMLAttribute(name: "onclick", value: value)
    }
}

struct Flashcard2Component: ElementaryInstanceComponent {
    typealias InstanceModel = FlashcardFrontModel
    typealias TemplateContext = Flashcard2TemplateContext
    
    let models: [any Mist.Model.Type] = [FlashcardFrontModel.self, FlashcardBackModel.self]
    let actions: [any Mist.Action] = [DeleteAction(), ShuffleTextAction(), FlipAction()]
    
    func makeTemplateContext(from primaryModel: FlashcardFrontModel, state: ComponentState?, on db: Database) async throws -> Flashcard2TemplateContext? {
        guard let id = primaryModel.id else { return nil }
        guard let backModel = try await FlashcardBackModel.find(id, on: db) else { return nil }
        let isFlipped = state?["isFlipped"]?.bool ?? false
        return Flashcard2TemplateContext(front: primaryModel, back: backModel, isFlipped: isFlipped)
    }

    func body(context: Flashcard2TemplateContext) -> some HTML {
        div(.class("flashcard \(context.isFlipped ? "flipped" : "")"), 
            .mistComponent("Flashcard2Component"), 
            .mistId(context.front.id?.uuidString ?? ""), 
            .onclick("if(!event.target.closest('button')) this.querySelector('.flip-trigger').click()")) {
            button(.class("flip-trigger"), .mistAction("flip"), .style("display: none;")) {}
            div(.class("flashcard-inner")) {
                div(.class("flashcard-front")) {
                    span(.class("flashcard-language-label")) { "🇺🇸" }
                    div(.class("flashcard-text")) { context.front.text }
                    div(.class("flashcard-actions")) {
                        button(.mistAction("ShuffleTextAction")) { "Shuffle" }
                        button(.mistAction("delete"), .class("btn-danger")) { "Delete" }
                    }
                }
                div(.class("flashcard-back")) {
                    span(.class("flashcard-language-label")) { "🇪🇸" }
                    div(.class("flashcard-text")) { context.back.text }
                }
            }
        }
    }
}
