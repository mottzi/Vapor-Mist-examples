import Elementary
import Vapor
import Mist

struct FlashcardPageElementary: HTMLDocument {
    let contexts: ComponentContexts

    let title = "Flashcards in Elementary — Mist Examples"
    var head: some HTML {
        link(.rel(.stylesheet), .href("/mistexamples.css?v=4"))
        meta(.name("viewport"), .content("width=device-width, initial-scale=1.0"))
        meta(.name(.description), .content("Database-backed live flashcards rendered with Elementary and Mist."))
    }
    
    var body: some HTML {
        header(.class("site-header")) {
            div(.class("site-header__inner")) {
                a(.href("/MistExamples"), .class("brand")) {
                    span(.class("mist-mark")) {
                        i {}
                        i {}
                        i {}
                    }
                    span { "Mist" }
                }
                a(.href("/MistExamples"), .class("site-header__link")) { "All examples" }
            }
        }

        main(.class("container detail-page detail-page--wide")) {
            header(.class("example-intro")) {
                span(.class("badge")) { "InstanceComponent · Elementary" }
                h1 { "Flashcards in typed Swift" }
                p {
                    "Create, shuffle, remove, and flip shared cards rendered entirely with Elementary markup."
                }
            }

            section(.class("demo-stage")) {
                div(.class("demo-stage__bar")) {
                    span(.class("live-status")) { "Live example" }
                    code { "FlashcardElementary" }
                }
                div(.class("demo-stage__body")) {
                    div(.class("demo-toolbar")) {
                        FlashcardAddButtonElementary().body(
                            context: ComponentContext(context: ModelContext(), state: [:]))
                        p { "Select a card to reveal its translation." }
                    }

                    div(.class("flashcard-grid"), .mistContainer(["FlashcardElementary"])) {
                        ForEach(contexts.contexts) { modelContext in
                            let component = FlashcardElementary()
                            let componentContext = ComponentContext(
                                context: modelContext, state: component.defaultState)
                            component.body(context: component.context(from: componentContext))
                        }
                    }
                }
            }

            section(.class("implementation-note")) {
                div {
                    p(.class("eyebrow")) { "How it works" }
                    h2 { "Database rows become component instances" }
                }
                p {
                    "Mist watches the two Fluent models behind each card and redraws affected instances after a create, shuffle, or delete. Flip state stays in per-client "
                    code { "ComponentState" }
                    ", so revealing a translation does not flip the card for everyone else."
                }
            }
        }
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
