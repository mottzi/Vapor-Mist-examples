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
    var body: some HTML {
        html {
            Elementary.body {
                CounterComponent().body(state: CounterState())
                script(.src("/morphdom.js")) {}
                script(.src("/mist.js")) {}
            }
        }
    }
}
