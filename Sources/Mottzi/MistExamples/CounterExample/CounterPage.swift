import Elementary

struct CounterPage: HTMLDocument {
    
    var title = "Counter Example Page"
    let initialHTML: String? // Added for SSR
    
    var head: some HTML {
        link(.rel(.stylesheet), .href("/mistexamples.css"))
    }
    
    var body: some HTML {
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                h1 { "Counter Example" }
                p(.class("desc mb-2")) { "A global counter demonstrating real-time manual state updates across all connected clients." }
                p(.class("desc p-4"), .style("border: 1px solid var(--color-danger); border-radius: var(--border-radius);")) {
                    "Re-renders only when its persistent state is set explicitly. This example holds a global "
                    code(.style("color: var(--color-accent); font-family: var(--font-mono);")) { "LiveState" }
                    " and demonstrates a server-side Action that increments the state, immediately broadcasting the new HTML to all connected clients."
                }
            }
            
            // Replaced static component with SSR Container
            div(
                HTMLAttribute(name: "mist-container", value: "CounterComponent"),
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
