import Elementary

struct CounterPage: HTMLDocument {
    
    var title = "Counter Example Page"
    let currentState: CounterState
    
    var head: some HTML {
        meta(.name("viewport"), .content("width=device-width, initial-scale=1.0"))
        link(.rel(.stylesheet), .href("/mistexamples.css"))
    }
    
    var body: some HTML {
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                span(.class("badge"), .style("margin-bottom: 0.75rem;")) { "ManualComponent" }
                h1(.style("margin-top: 0;")) { "Counter Example" }
            }
            
            // Replaced static component with SSR Container
            div(
                .mistContainer(["CounterComponent"]),
                .mistSSR(true)
            ) {
                CounterComponent().body(state: currentState)
            }
            
            div(.class("mt-4")) {
                p(.class("desc")) {
                    "A global counter demonstrating real-time manual state updates across all connected clients. "
                    "Re-renders only when its persistent state is set explicitly. This example holds a global "
                    code(.style("color: var(--color-accent); font-family: var(--font-mono);")) { "LiveState" }
                    " and demonstrates a server-side Action that increments the state, immediately broadcasting the new HTML to all connected clients."
                }
            }
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
