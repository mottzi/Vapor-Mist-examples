import Vapor
import Fluent
import Mist
import Elementary

struct FlashcardContext: Encodable {
    let front: FlashcardFrontModel
    let back: FlashcardBackModel
    let isFlipped: Bool
}

struct Flashcard2Component: InstanceComponent {

    let models: [any Mist.Model.Type] = [
        FlashcardFrontModel.self,
        FlashcardBackModel.self
    ]
    
    let actions: [any Mist.Action] = [
        DeleteAction(),
        ShuffleTextAction(),
        FlipAction()
    ]

    func context(from context: ComponentContext) -> FlashcardContext {
        FlashcardContext(
            front: context[FlashcardFrontModel.self] ?? FlashcardFrontModel(text: "Missing Front"),
            back: context[FlashcardBackModel.self] ?? FlashcardBackModel(text: "Missing Back"),
            isFlipped: context.state["isFlipped"]?.bool ?? false
        )
    }

    @HTMLBuilder
    func body(context: FlashcardContext) -> some HTML {
        div(
            .class("flashcard \(context.isFlipped ? "flipped" : "")"),
            .mistComponent("Flashcard2Component"),
            .mistId(context.front.id),
            .onclick(
                "if(!event.target.closest('button')) this.querySelector('.flip-trigger').click()")
        ) {
            button(
                .class("flip-trigger"),
                .mistAction("flip"),
                .style("display: none;")
            ) {}
            div(.class("flashcard-inner")) {
                div(.class("flashcard-front")) {
                    span(.class("flashcard-language-label")) { "🇺🇸" }
                    div(.class("flashcard-text")) {
                        context.front.text
                    }
                    div(.class("flashcard-actions")) {
                        button(.mistAction("ShuffleTextAction")) { "Shuffle" }
                        button(.mistAction("delete"), .class("btn-danger")) { "Delete" }
                    }
                }
                div(.class("flashcard-back")) {
                    span(.class("flashcard-language-label")) { "🇪🇸" }
                    div(.class("flashcard-text")) {
                        context.back.text
                    }
                }
            }
        }
    }
}

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
    public static func onclick(_ value: String) -> HTMLAttribute {
        HTMLAttribute(name: "onclick", value: value)
    }
}
