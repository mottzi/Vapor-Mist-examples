import Elementary

struct CounterPage: HTMLDocument {
    
    let title = "Counter Example Page"

    var head: some HTML { EmptyHTML() }

    var body: some HTML {
        CounterComponent()
            .body(state: CounterState())
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
    
}

//import Elementary
//
//struct CounterPage2: HTMLDocument {
//    
//    var title = "Counter Example Page"
//
//    var head: some HTML {
//        link(.rel(.stylesheet), .href("/mistexamples.css"))
//    }
//
//    var body: some HTML {
//
//        main(.class("container")) {
//            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
//            
//            header(.class("mb-4")) {
//                h1 { "Counter Example" }
//                p(.class("desc")) { "A global counter demonstrating real-time manual state updates across all connected clients." }
//            }
//            
//            CounterComponent()
//                .body(state: CounterState())
//        }
//        
//        script(.src("/morphdom.js")) {}
//        script(.src("/mist.js")) {}
//    }
//}
