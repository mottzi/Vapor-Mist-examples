import Elementary
import Mist
import Vapor
import VaporElementary

extension Application {

    func useMistExamples() {

        self.get("MistExamples") { _ in
            HTMLResponse { MistExamplesPage() }
        }

        self.get("CounterExample") { req async throws in
            let counter = await req.application.mistComponent(CounterComponent.self)
            let currentState = await counter?.state.current ?? CounterState()
            return HTMLResponse { CounterPage(currentState: currentState) }
        }

        self.get("SystemMonitorExample") { req async throws in
            async let memory = req.application.mistComponent(MemoryUsageComponent.self)?
                .renderInitial(app: req.application)
            async let cpu = req.application.mistComponent(CpuLoadComponent.self)?.renderInitial(
                app: req.application)
            async let clients = req.application.mistComponent(ConnectedClientsComponent.self)?
                .renderInitial(app: req.application)
            async let stress = req.application.mistComponent(StressTestComponent.self)?
                .renderInitial(app: req.application)

            let memoryHTML = await memory ?? nil
            let cpuHTML = await cpu ?? nil
            let clientsHTML = await clients ?? nil
            let stressHTML = await stress ?? nil

            return HTMLResponse {
                SystemMemoryPage(
                    memoryHTML: memoryHTML,
                    cpuHTML: cpuHTML,
                    clientsHTML: clientsHTML,
                    stressHTML: stressHTML
                )
            }
        }

        self.get("LivePollingExample") { req async throws in
            let polling = await req.application.mistComponent(LiveVotingComponent.self)
            let initialHTML = await polling?.renderInitial(app: req.application)
            return HTMLResponse { LiveVotingPage(initialHTML: initialHTML) }
        }

        self.get("FlashcardElementary") { req async throws in
            let contexts = try await FlashcardElementary().makeContext(ofAll: req.db)
            return HTMLResponse { FlashcardPageElementary(contexts: contexts) }
        }

        self.get("FlashcardLeaf") { req async throws -> View in
            let context = try await FlashcardLeaf().makeContext(ofAll: req.db)
            return try await req.view.render("FlashcardExample/FlashcardPageLeaf", context)
        }

        self.get("PatientMonitorExample") { req async throws -> View in
            let bundle = try await PatientComponent().makeContext(ofAll: req.db)
            return try await req.view.render("PatientMonitorExample/PatientMonitorPage", bundle)
        }
    }

}

struct MistExamplesPage: HTMLDocument {

    let title = "Mist Examples"
    var head: some HTML {
        meta(.name("viewport"), .content("width=device-width, initial-scale=1.0"))
        meta(
            .name(.description),
            .content("Runnable examples of server-driven Swift interfaces built with Mist and Vapor."))
        link(.rel(.stylesheet), .href("/mistexamples.css?v=4"))
    }

    var body: some HTML {
        a(.href("#examples"), .class("skip-link")) { "Skip to examples" }

        header(.class("site-header")) {
            div(.class("site-header__inner")) {
                a(.href("https://mottzi.codes"), .class("brand")) {
                    span(.class("mist-mark")) {
                        i {}
                        i {}
                        i {}
                    }
                    span { "Mist" }
                }
                span(.class("site-header__section")) { "Interactive examples" }
            }
        }

        main(.class("container examples-home")) {
            section(.class("examples-hero")) {
                div(.class("examples-hero__copy")) {
                    p(.class("eyebrow")) { "Mist + Vapor" }
                    h1 { "Live interfaces, rendered in Swift." }
                    p(.class("hero-lede")) {
                        "Explore six focused examples of server state becoming responsive browser UI—without building a second application in JavaScript."
                    }
                }

                aside(.class("signal-card")) {
                    div(.class("signal-card__bar")) {
                        span(.class("live-status")) { "Connected" }
                        code { "Mist" }
                    }
                    ol(.class("signal-path")) {
                        li {
                            span { "State" }
                            strong { "Changes on the server" }
                        }
                        li {
                            span { "Render" }
                            strong { "Swift produces fresh HTML" }
                        }
                        li {
                            span { "Update" }
                            strong { "The component patches in place" }
                        }
                    }
                }
            }

            section(.class("examples-section"), .id("examples")) {
                header(.class("section-heading")) {
                    div {
                        p(.class("eyebrow")) { "Runnable demos" }
                        h2 { "Choose an example" }
                    }
                    p { "Each page is live. Open two browser windows to see shared updates arrive in both." }
                }

                ul(.class("example-grid")) {
                    li(.class("example-card")) {
                        a(.href("/FlashcardElementary")) {
                            div(.class("example-card__meta")) {
                                span(.class("badge")) { "InstanceComponent" }
                                span(.class("example-card__arrow")) { "↗" }
                            }
                            h3 { "Flashcards · Elementary" }
                            p { "Typed Swift markup, database-backed cards, and per-client flip state." }
                        }
                    }
                    li(.class("example-card")) {
                        a(.href("/FlashcardLeaf")) {
                            div(.class("example-card__meta")) {
                                span(.class("badge")) { "InstanceComponent" }
                                span(.class("example-card__arrow")) { "↗" }
                            }
                            h3 { "Flashcards · Leaf" }
                            p { "The same live behavior rendered through familiar Leaf templates." }
                        }
                    }
                    li(.class("example-card")) {
                        a(.href("/PatientMonitorExample")) {
                            div(.class("example-card__meta")) {
                                span(.class("badge")) { "InstanceComponent" }
                                span(.class("example-card__arrow")) { "↗" }
                            }
                            h3 { "Patient monitor" }
                            p { "Stable patient records joined with changing bedside telemetry." }
                        }
                    }
                    li(.class("example-card")) {
                        a(.href("/CounterExample")) {
                            div(.class("example-card__meta")) {
                                span(.class("badge")) { "ManualComponent" }
                                span(.class("example-card__arrow")) { "↗" }
                            }
                            h3 { "Shared counter" }
                            p { "One explicit state change, broadcast to every connected client." }
                        }
                    }
                    li(.class("example-card")) {
                        a(.href("/SystemMonitorExample")) {
                            div(.class("example-card__meta")) {
                                span(.class("badge")) { "LiveComponent" }
                                span(.class("example-card__arrow")) { "↗" }
                            }
                            h3 { "System monitor" }
                            p { "Memory, load, and client metrics refreshed on a schedule." }
                        }
                    }
                    li(.class("example-card")) {
                        a(.href("/LivePollingExample")) {
                            div(.class("example-card__meta")) {
                                span(.class("badge")) { "PollingComponent" }
                                span(.class("example-card__arrow")) { "↗" }
                            }
                            h3 { "Language poll" }
                            p { "Database votes aggregated and redrawn every second." }
                        }
                    }
                }
            }
        }

        footer(.class("site-footer")) {
            div(.class("site-footer__inner")) {
                p { "Mist is server-driven UI for Swift and Vapor." }
                div {
                    a(.href("https://mottzi.codes/Mist")) { "How Mist works" }
                    a(.href("https://github.com/mottzi/Mist")) { "GitHub ↗" }
                }
            }
        }
    }

}
