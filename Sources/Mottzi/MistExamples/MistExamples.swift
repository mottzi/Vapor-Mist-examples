import Vapor
import VaporElementary
import Elementary
import Mist

struct TeamDirectoryPageContext: Encodable {
    let contexts: [ModelContext]
    let division: String
}

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
        
        self.get("CounterExample2") { req async throws -> View in
            let counter = await req.application.mistComponent(CounterComponent2.self)
            let currentState = await counter?.state.current ?? CounterState()
            return try await req.view.render(
                "CounterExample2/CounterExample2Page",
                ["count": currentState.count]
            )
        }

        self.get("SystemMonitorExample") { req async throws in
            async let memory = req.application.mistComponent(MemoryUsageComponent.self)?.renderInitial(app: req.application)
            async let cpu = req.application.mistComponent(CpuLoadComponent.self)?.renderInitial(app: req.application)
            async let clients = req.application.mistComponent(ConnectedClientsComponent.self)?.renderInitial(app: req.application)
            async let stress = req.application.mistComponent(StressTestComponent.self)?.renderInitial(app: req.application)

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

        self.get("FlashcardExample") { req async throws -> View in
            let context = try await FlashcardComponent().makeContext(ofAll: req.db)
            return try await req.view.render("FlashcardExample/FlashcardExamplePage", context)
        }

        self.get("teamprofile", ":division") { req async throws -> View in
            let division = try req.parameters.require("division")
            guard TeamProfileExample.divisions.contains(division) else {
                throw Abort(.notFound)
            }
            let component = ProfileComponent(division: division)
            let bundle = try await component.makeContext(ofAll: req.db)
            let page = TeamDirectoryPageContext(contexts: bundle.contexts, division: division)
            return try await req.view.render("TeamProfileExample/TeamProfileExamplePage", page)
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
                p(.class("desc")) { "A collection of interactive components built with Mist and Vapor." }
            }

            section {
                ul {
                    li { 
                        a(.href("/FlashcardExample")) { 
                            div(.class("stack")) {
                                span(.class("badge")) { "InstanceComponent" }
                                span { "Flashcards" }
                                p(.class("desc")) { "Interactive cards with real-time sync." }
                            }
                        } 
                    }
                    li {
                        a(.href("/teamprofile/europe")) {
                            div(.class("stack")) {
                                span(.class("badge")) { "InstanceComponent" }
                                span { "Team directory" }
                                p(.class("desc")) { "Users + profiles by division; try east-coast too." }
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
                        a(.href("/CounterExample2")) { 
                            div(.class("stack")) {
                                span(.class("badge")) { "ManualComponent" }
                                span { "Counter (Leaf)" }
                                p(.class("desc")) { "Global counter with manual state updates (Leaf)." }
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
                                p(.class("desc")) { "Real-time voting and auto-aggregated results." }
                            }
                        } 
                    }
                }
            }
        }
    }

}
