import Elementary
import Vapor
import Mist

struct FlashcardExample2Page: HTMLDocument {
    let contexts: ComponentContexts

    let title = "Flashcards 2"
    var head: some HTML {
        link(.rel(.stylesheet), .href("/mistexamples.css"))
        meta(.name("viewport"), .content("width=device-width, initial-scale=1.0"))
    }
    
    var body: some HTML {
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            header(.class("mb-4")) {
                span(.class("badge"), .style("margin-bottom: 0.75rem;")) { "ElementaryInstanceComponent" }
                h1(.style("margin-top: 0;")) { "Flashcards (Elementary)" }
            }
            
            Flashcard2CreateComponent().body(context: ComponentContext(context: ModelContext(), state: [:]))
            
            div(.class("flashcard-grid"), .mistContainer(["Flashcard2Component"])) {
                ForEach(contexts.contexts) { modelContext in
                    let component = Flashcard2Component()
                    let componentContext = ComponentContext(context: modelContext, state: component.defaultState)
                    component.body(context: component.context(from: componentContext))
                }
            }
            
            div(.class("mt-4")) {
                p(.class("desc")) { "Tied to database rows; re-renders automatically when Mist detects Fluent create, update, or delete events. This example tracks two models per card. It demonstrates Actions for database mutations (shuffling, deleting) which sync globally, and per-client ComponentState (flipping the card) which only re-renders for the acting client." }
            }
        }
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
