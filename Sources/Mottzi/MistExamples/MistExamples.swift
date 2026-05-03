import Vapor
import VaporElementary
import Elementary

extension Application {
    
    func useMistExamples() {
        
        self.get("MistExamples") { _ in
            HTMLResponse {
                MistExamplesPage()
            }
        }
        
        self.get("CounterExample") { r in
            HTMLResponse {
                html {
                    body {
                        CounterComponent()
                            .view(state: CounterState()) //
                        script(.src("/morphdom.js")) {}
                        script(.src("/mist.js")) {}
                    }
                }
            }
            
        }

        self.get("SystemMonitorExample") { _ in
            HTMLResponse {
                SystemMemoryPage()
            }
        }

        self.get("LivePollingExample") { _ in
            HTMLResponse {
                LiveVotingPage()
            }
        }

        self.get("FlashcardExample") { request async throws -> View in
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
                p { "A collection of interactive components built with Mist and Vapor." }
            }

            section {
                ul {
                    li { 
                        a(.href("/FlashcardExample")) { 
                            div(.class("stack")) {
                                span { "Flashcard Example" }
                                p(.class("desc")) { "A dynamic flashcard system with persistent storage and real-time updates." }
                            }
                        } 
                    }
                    li { 
                        a(.href("/CounterExample")) { 
                            div(.class("stack")) {
                                span { "Counter Example" }
                                p(.class("desc")) { "A simple global counter demonstrating manual state management." }
                            }
                        } 
                    }
                    li { 
                        a(.href("/SystemMonitorExample")) { 
                            div(.class("stack")) {
                                span { "System Monitor Example" }
                                p(.class("desc")) { "A live server health widget demonstrating periodic state refreshes." }
                            }
                        } 
                    }
                    li { 
                        a(.href("/LivePollingExample")) { 
                            div(.class("stack")) {
                                span { "Live Polling Example" }
                                p(.class("desc")) { "A polling widget aggregating database records automatically." }
                            }
                        } 
                    }
                }
            }
        }
    }

}
