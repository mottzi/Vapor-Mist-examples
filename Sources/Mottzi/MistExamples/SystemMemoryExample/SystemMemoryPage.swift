// Sources/Mottzi/MistExamples/SystemMemoryExample/SystemMemoryPage.swift

import Elementary

struct SystemMemoryPage: HTMLDocument {
    var title = "System Monitor Example"
    let memoryHTML: String?
    let cpuHTML: String?
    let clientsHTML: String?
    let stressHTML: String?

    var head: some HTML {
        meta(.name(.description), .content("Live updating server metrics with Mist"))
        link(.rel(.stylesheet), .href("/mistexamples.css"))
    }

    var body: some HTML {
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                span(.class("badge"), .style("margin-bottom: 0.75rem;")) { "LiveComponent" }
                h1(.style("margin-top: 0;")) { "System Monitor Example" }
                p(.class("desc")) { "A live server health widget that updates automatically every 2 seconds without user interaction." }
                p(.class("desc")) {
                    "Periodically refreshes its persistent state and re-renders when the state changes. Owns a "
                    code(.style("color: var(--color-accent); font-family: var(--font-mono);")) { "LiveState" }
                    " and refreshes it on a 2-second schedule by reading the host server's memory usage and CPU load. Broadcasts new HTML only when the value changes."
                }
            }
            
            div(.class("stack"), .style("gap: 2rem; align-items: center;")) {
                div(.class("inline"), .style("justify-content: center; gap: 2rem; flex-wrap: wrap;")) {
                    div(
                        HTMLAttribute(name: "mist-container", value: "MemoryUsageComponent"),
                        HTMLAttribute(name: "mist-ssr", value: memoryHTML != nil ? "true" : "false"),
                    ) {
                        if let html = memoryHTML {
                            HTMLRaw(html)
                        }
                    }

                    div(
                        HTMLAttribute(name: "mist-container", value: "CpuLoadComponent"),
                        HTMLAttribute(name: "mist-ssr", value: cpuHTML != nil ? "true" : "false"),
                    ) {
                        if let html = cpuHTML {
                            HTMLRaw(html)
                        }
                    }

                    div(
                        HTMLAttribute(name: "mist-container", value: "ConnectedClientsComponent"),
                        HTMLAttribute(name: "mist-ssr", value: clientsHTML != nil ? "true" : "false"),
                    ) {
                        if let html = clientsHTML {
                            HTMLRaw(html)
                        }
                    }
                }

                div(
                    HTMLAttribute(name: "mist-container", value: "StressTestComponent"),
                    HTMLAttribute(name: "mist-ssr", value: stressHTML != nil ? "true" : "false"),
                ) {
                    if let html = stressHTML {
                        HTMLRaw(html)
                    }
                }
            }
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
