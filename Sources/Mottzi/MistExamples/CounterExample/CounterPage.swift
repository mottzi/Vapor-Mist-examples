import Elementary

struct CounterPage: HTMLDocument {
    
    var title = "Counter Example Page"

    var head: some HTML {
        meta(.name(.description), .content("Typesafe HTML in modern Swift"))
        link(.rel(.stylesheet), .href("/mistexamples.css"))
    }

    var body: some HTML {

        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                h1 { "Counter Example" }
                p(.class("desc")) { "A global counter demonstrating real-time manual state updates across all connected clients." }
            }
            
            CounterComponent()
                .body(state: CounterState())
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}

struct CounterPageWrapper: HTML {
    // This property name 'body' conflicts with the HTML tag 'body'
    var body: some HTML {
        html {
            head {
                title { "Counter Example Page" }
                meta(.name(.description), .content("Typesafe HTML in modern Swift"))
                link(.rel(.stylesheet), .href("/mistexamples.css"))
            }

            // Prefix with the module name to avoid the 'Use of body refers to instance method' error
            Elementary.body {
                main(.class("container")) {
                    a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
                    
                    header(.class("mb-4")) {
                        h1 { "Counter Example" }
                        p(.class("desc")) { "A global counter demonstrating real-time manual state updates across all connected clients." }
                    }
                    
                    // Render the component
                    CounterComponent().body(state: CounterState())
                }
                
                // Scripts for Mist reactivity
                script(.src("/morphdom.js")) {}
                script(.src("/mist.js")) {}
            }
        }
    }
}
