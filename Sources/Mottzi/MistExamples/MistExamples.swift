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
        link(.rel(.stylesheet), .href("/mistexamples.css"))
    }

    var body: some HTML {
        main(.class("container")) {
            header(.class("mb-4")) {
                h1 { "Mist Examples" }
                p(.class("desc")) {
                    "A collection of interactive components built with Mist and Vapor."
                }
            }

            section {
                ul {
                    li {
                        a(.href("/FlashcardElementary")) {
                            div(.class("stack")) {
                                span(.class("badge")) { "InstanceComponent" }
                                span { "Flashcards (Elementary)" }
                                p(.class("desc")) { "Interactive cards with real-time sync." }
                            }
                        }
                    }
                    li {
                        a(.href("/FlashcardLeaf")) {
                            div(.class("stack")) {
                                span(.class("badge")) { "InstanceComponent" }
                                span { "Flashcards (Leaf)" }
                                p(.class("desc")) { "Interactive cards with real-time sync." }
                            }
                        }
                    }
                    li {
                        a(.href("/PatientMonitorExample")) {
                            div(.class("stack")) {
                                span(.class("badge")) { "InstanceComponent" }
                                span { "Patient Monitor" }
                                p(.class("desc")) {
                                    "Split-table architecture: EMR records + Live Telemetry."
                                }
                            }
                        }
                    }
                    li {
                        a(.href("/CounterExample")) {
                            div(.class("stack")) {
                                span(.class("badge")) { "ManualComponent" }
                                span { "Counter" }
                                p(.class("desc")) { "Global counter with manual state updates." }
                            }
                        }
                    }
                    li {
                        a(.href("/SystemMonitorExample")) {
                            div(.class("stack")) {
                                span(.class("badge")) { "LiveComponent" }
                                span { "System Monitor" }
                                p(.class("desc")) { "Live memory and CPU usage with auto-refresh." }
                            }
                        }
                    }
                    li {
                        a(.href("/LivePollingExample")) {
                            div(.class("stack")) {
                                span(.class("badge")) { "PollingComponent" }
                                span { "Live Polling" }
                                p(.class("desc")) {
                                    "Real-time voting and auto-aggregated results."
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
