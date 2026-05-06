import Vapor
import Elementary
import Mist

struct SportsMatchPage: HTMLDocument {
    let title = "Live Sports Dashboard"
    let matchHTMLs: [String]

    var head: some HTML {
        link(.rel(.stylesheet), .href("/mistexamples.css"))
        link(.rel(.stylesheet), .href("/sportsmatch.css"))
    }

    var body: some HTML {
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                h1 { "Live Sports Dashboard" }
                p(.class("desc")) { 
                    "Demo of "
                    span(.class("inline-code")) { "InstanceComponent" }
                    " using multiple models ("
                    span(.class("inline-code")) { "Match" }
                    " and "
                    span(.class("inline-code")) { "Scoreboard" }
                    ") joined by shared ID."
                }
            }

            section(.class("sports-grid")) {
                for html in matchHTMLs {
                    HTMLRaw(html)
                }
            }
            
            footer(.class("mt-4 text-center")) {
                p(.class("desc")) { "The Scoreboard model updates in real-time, while the Match identity stays stable." }
            }
        }
    }
}
