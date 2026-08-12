import Elementary

struct CounterPage: HTMLDocument {
    
    var title = "Shared Counter — Mist Examples"
    let currentState: CounterState
    
    var head: some HTML {
        meta(.name("viewport"), .content("width=device-width, initial-scale=1.0"))
        meta(.name(.description), .content("A shared server-side counter built with a Mist ManualComponent."))
        link(.rel(.stylesheet), .href("/mistexamples.css?v=4"))
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

        main(.class("container detail-page")) {
            header(.class("example-intro")) {
                span(.class("badge")) { "ManualComponent" }
                h1 { "Shared counter" }
                p {
                    "Increment one server-owned value and watch every connected browser move together."
                }
            }

            section(.class("demo-stage")) {
                div(.class("demo-stage__bar")) {
                    span(.class("live-status")) { "Live example" }
                    code { "CounterComponent" }
                }
                div(.class("demo-stage__body demo-stage__body--center")) {
                    div(
                        .mistContainer(["CounterComponent"]),
                        .mistSSR(true)
                    ) {
                        CounterComponent().body(state: currentState)
                    }
                }
            }

            section(.class("implementation-note")) {
                div {
                    p(.class("eyebrow")) { "How it works" }
                    h2 { "An explicit state change" }
                }
                p {
                    "The component owns a global "
                    code { "LiveState" }
                    ". Its server-side action increments that value, renders fresh HTML, and broadcasts only the updated component to every subscribed client."
                }
            }
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
