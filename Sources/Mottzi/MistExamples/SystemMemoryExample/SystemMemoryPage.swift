// Sources/Mottzi/MistExamples/SystemMemoryExample/SystemMemoryPage.swift

import Elementary

struct SystemMemoryPage: HTMLDocument {
    var title = "System Monitor Example"
    let initialHTML: String? // Added for SSR

    var head: some HTML {
        meta(.name(.description), .content("Live updating server metrics with Mist"))
        link(.rel(.stylesheet), .href("/mistexamples.css"))
    }

    var body: some HTML {
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                h1 { "System Monitor Example" }
                p(.class("desc mb-2")) { "A live server health widget that updates automatically every 2 seconds without user interaction." }
                p(.class("desc p-4"), .style("border: 1px solid var(--color-danger); border-radius: var(--border-radius);")) {
                    "Periodically refreshes its persistent state and re-renders when the state changes. Owns a "
                    code(.style("color: var(--color-accent); font-family: var(--font-mono);")) { "LiveState" }
                    " and refreshes it on a 2-second schedule by reading the host server's memory usage. Broadcasts new HTML only when the value changes."
                }
            }
            
            // Replaced static component with SSR Container
            div(
                HTMLAttribute(name: "mist-container", value: "SystemMemoryComponent"),
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
