// Sources/Mottzi/MistExamples/LivePollingExample/LiveVotingPage.swift

import Elementary

struct LiveVotingPage: HTMLDocument {
    
    var title = "Swift vs. Kotlin"
    let initialHTML: String? // Added for SSR

    var head: some HTML {
        meta(.name(.description), .content("Live database aggregation with Mist PollingComponent"))
        link(.rel(.stylesheet), .href("/mistexamples.css"))
        style {
            """
            progress { width: 100%; height: 24px; accent-color: #F05138; }
            .accent-purple { accent-color: #7F52FF; }
            .poll-grid { display: grid; gap: 1rem; }
            """
        }
    }

    var body: some HTML {
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                span(.class("badge"), .style("margin-bottom: 0.75rem;")) { "PollingComponent" }
                h1(.style("margin-top: 0;")) { "THE MOBILE DEVELOPER BATTLE" }
                p(.class("desc")) { "Two modern languages enter, only one leaves. Choose your favorite syntax and watch the results update in real-time." }
                p(.class("desc")) {
                    "Manually reads from the database periodically and re-renders when the result changes. This component polls the database every 2s to aggregate votes. It demonstrates server-side Actions that insert rows, while the polling loop naturally picks up the changes."
                }
            }
            
            // Replaced static component with SSR Container
            div(
                .class("poll-grid"),
                HTMLAttribute(name: "mist-container", value: "live-voting-results"),
                HTMLAttribute(name: "mist-ssr", value: initialHTML != nil ? "true" : "false"),
            ) {
                if let html = initialHTML {
                    HTMLRaw(html)
                }
            }
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
