import Vapor
import VaporElementary
import Elementary

extension Application {
    
    func useMistExamples() {
        
        self.get("MistExamples") { _ in
            HTMLResponse { MistExamplesPage() }
        }
        
        self.get("CounterExample") { req async throws in
            let counter = await req.application.mistComponent(CounterComponent.self)
            let initialHTML = await counter?.renderInitial(app: req.application)
            return HTMLResponse { CounterPage(initialHTML: initialHTML) }
        }

        self.get("SystemMonitorExample") { req async throws in
            let monitor = await req.application.mistComponent(SystemMemoryComponent.self)
            let initialHTML = await monitor?.renderInitial(app: req.application)
            return HTMLResponse { SystemMemoryPage(initialHTML: initialHTML) }
        }

        self.get("LivePollingExample") { req async throws in
            let polling = await req.application.mistComponent(LiveVotingComponent.self)
            let initialHTML = await polling?.renderInitial(app: req.application)
            return HTMLResponse { LiveVotingPage(initialHTML: initialHTML) }
        }

        self.get("FlashcardExample") { request async throws -> View in
            // InstanceComponent: Left unchanged as per SSR scope constraints
            let context = try await FlashcardComponent().makeContext(ofAll: request.db)
            return try await request.view.render("FlashcardExample/FlashcardExamplePage", context)
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
                                p(.class("desc")) { "Live memory usage with auto-refresh." }
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