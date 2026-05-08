import Elementary
import Fluent
import Mist
import Vapor

extension HTMLAttribute where Tag: HTMLTrait.Attributes.Global {
    public static func onclick(_ value: String) -> HTMLAttribute {
        HTMLAttribute(name: "onclick", value: value)
    }
}

struct Flashcard2Component: InstanceComponent {

    let models: [any Mist.Model.Type] = [FlashcardFrontModel.self, FlashcardBackModel.self]
    let actions: [any Mist.Action] = [DeleteAction(), ShuffleTextAction(), FlipAction()]

    @HTMLBuilder
    func body(context: ComponentContext) -> some HTML {
        let isFlipped = context.state["isFlipped"]?.bool ?? false

        div(
            .class("flashcard \(isFlipped ? "flipped" : "")"),
            .mistComponent("Flashcard2Component"),
            .mistId(context[\FlashcardFrontModel.id]?.uuidString ?? ""),
            .onclick(
                "if(!event.target.closest('button')) this.querySelector('.flip-trigger').click()")
        ) {
            button(.class("flip-trigger"), .mistAction("flip"), .style("display: none;")) {}
            div(.class("flashcard-inner")) {
                div(.class("flashcard-front")) {
                    span(.class("flashcard-language-label")) { "🇺🇸" }
                    div(.class("flashcard-text")) {
                        context[\FlashcardFrontModel.text] ?? "Missing Front"
                    }
                    div(.class("flashcard-actions")) {
                        button(.mistAction("ShuffleTextAction")) { "Shuffle" }
                        button(.mistAction("delete"), .class("btn-danger")) { "Delete" }
                    }
                }
                div(.class("flashcard-back")) {
                    span(.class("flashcard-language-label")) { "🇪🇸" }
                    div(.class("flashcard-text")) {
                        context[\FlashcardBackModel.text] ?? "Missing Back"
                    }
                }
            }
        }
    }
}
