import Elementary

struct SystemMemoryPage: HTMLDocument {
    var title = "System Monitor Example"

    var head: some HTML {
        meta(.name(.description), .content("Live updating server metrics with Mist"))
        link(.rel(.stylesheet), .href("/mistexamples.css"))
    }

    var body: some HTML {
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                h1 { "System Monitor Example" }
                p(.class("desc")) { "A live server health widget that updates automatically every 2 seconds without user interaction." }
            }
            
            SystemMemoryComponent()
                .body(state: SystemMemoryComponent.SystemMetrics(memoryUsage: 0))
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
