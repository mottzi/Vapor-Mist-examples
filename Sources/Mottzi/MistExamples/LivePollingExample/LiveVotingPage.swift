// Sources/Mottzi/MistExamples/LivePollingExample/LiveVotingPage.swift

import Elementary

struct LiveVotingPage: HTMLDocument {
    
    var title = "Language Poll — Mist Examples"
    let initialHTML: String?

    var head: some HTML {
        meta(.name(.description), .content("Live database aggregation with Mist PollingComponent"))
        meta(.name("viewport"), .content("width=device-width, initial-scale=1.0"))
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
                span(.class("badge")) { "PollingComponent" }
                h1 { "Swift or Kotlin?" }
                p {
                    "Cast a vote and watch the shared result settle as Mist re-aggregates the database."
                }
            }

            section(.class("demo-stage")) {
                div(.class("demo-stage__bar")) {
                    span(.class("live-status")) { "Live example" }
                    code { "1 second poll" }
                }
                div(.class("demo-stage__body demo-stage__body--center")) {
                    div(
                        .class("poll-grid"),
                        .mistContainer(["LiveVotingComponent"]),
                        .mistSSR(initialHTML != nil)
                    ) {
                        if let html = initialHTML {
                            HTMLRaw(html)
                        }
                    }
                }
            }

            section(.class("implementation-note")) {
                div {
                    p(.class("eyebrow")) { "How it works" }
                    h2 { "Fresh data, only when it changes" }
                }
                p {
                    "Each vote inserts a database row. The "
                    code { "PollingComponent" }
                    " aggregates both choices once a second and redraws the result only when the returned context differs."
                }
            }
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
