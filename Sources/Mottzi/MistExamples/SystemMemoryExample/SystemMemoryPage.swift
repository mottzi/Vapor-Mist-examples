// Sources/Mottzi/MistExamples/SystemMemoryExample/SystemMemoryPage.swift

import Elementary

struct SystemMemoryPage: HTMLDocument {
    var title = "System Monitor — Mist Examples"
    let memoryHTML: String?
    let cpuHTML: String?
    let clientsHTML: String?
    let stressHTML: String?

    var head: some HTML {
        meta(.name(.description), .content("Live updating server metrics with Mist"))
        meta(.name("viewport"), .content("width=device-width, initial-scale=1.0"))
        link(.rel(.stylesheet), .href("/mistexamples.css?v=4"))
    }

    var body: some HTML {
        header(.class("site-header")) {
            div(.class("site-header__inner")) {
                a(.href("/MistExamples"), .class("brand")) {
                    span(.class("mist-mark")) {
                        i {}
                        i {}
                        i {}
                    }
                    span { "Mist" }
                }
                a(.href("/MistExamples"), .class("site-header__link")) { "All examples" }
            }
        }

        main(.class("container detail-page detail-page--wide")) {
            header(.class("example-intro")) {
                span(.class("badge")) { "LiveComponent" }
                h1 { "System monitor" }
                p {
                    "Watch server memory, load, and connected clients refresh without a page reload."
                }
            }

            section(.class("demo-stage")) {
                div(.class("demo-stage__bar")) {
                    span(.class("live-status")) { "Live example" }
                    code { "2 second refresh" }
                }
                div(.class("demo-stage__body")) {
                    div(.class("metrics-grid")) {
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

                    div(.class("metrics-toolbar")) {
                        div(
                            .mistContainer(["StressTestComponent"]),
                            .mistSSR(stressHTML != nil)
                        ) {
                            if let html = stressHTML {
                                HTMLRaw(html)
                            }
                        }
                    }
                }
            }

            section(.class("implementation-note")) {
                div {
                    p(.class("eyebrow")) { "How it works" }
                    h2 { "State refreshed on a schedule" }
                }
                p {
                    "Each metric owns a "
                    code { "LiveState" }
                    " and samples the host every two seconds. Mist renders and broadcasts a component only when its value changes, so idle metrics stay quiet."
                }
            }
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}
