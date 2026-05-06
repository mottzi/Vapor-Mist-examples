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
        main(.class("container"), .style("max-width: 1000px;")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                span(.class("badge"), .style("margin-bottom: 0.75rem;")) { "LiveComponent" }
                h1(.style("margin-top: 0;")) { "System Monitor Example" }
            }
            
            div(.class("stack"), .style("gap: 2rem; align-items: center;")) {
                div(.class("inline"), .style("justify-content: center; gap: 2rem; flex-wrap: wrap; width: 100%;")) {
                    div(
                        .mistContainer(["MemoryUsageComponent"]),
                        .mistSSR(memoryHTML != nil)
                    ) {
                        if let html = memoryHTML {
                            HTMLRaw(html)
                        }
                    }

                    div(
                        .mistContainer(["CpuLoadComponent"]),
                        .mistSSR(cpuHTML != nil)
                    ) {
                        if let html = cpuHTML {
                            HTMLRaw(html)
                        }
                    }

                    div(
                        .mistContainer(["ConnectedClientsComponent"]),
                        .mistSSR(clientsHTML != nil)
                    ) {
                        if let html = clientsHTML {
                            HTMLRaw(html)
                        }
                    }
                }

                div(
                    .mistContainer(["StressTestComponent"]),
                    .mistSSR(stressHTML != nil)
                ) {
                    if let html = stressHTML {
                        HTMLRaw(html)
                    }
                }
            }

            div(.class("mt-4")) {
                p(.class("desc")) {
                    "A live server health widget that updates automatically every 2 seconds without user interaction. "
                    "Periodically refreshes its persistent state and re-renders when the state changes. Owns a "
                    code(.style("color: var(--color-accent); font-family: var(--font-mono);")) { "LiveState" }
                    " and refreshes it on a 2-second schedule by reading the host server's memory usage and CPU load. Broadcasts new HTML only when the value changes."
                }
            }
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
