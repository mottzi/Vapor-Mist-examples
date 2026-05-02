import Vapor
import VaporElementary
import Elementary

extension Application {
    
    func useMistExamples() {
        
        self.get("MistExamples") { _ in
            HTMLResponse {
                MistExamplesIndexPage()
            }
        }
        
        self.get("CounterExample") { _ in
            HTMLResponse {
                CounterExamplePage()
            }
        }

        self.get("FlashcardExample") { request async throws -> View in
            let context = try await FlashcardComponent().makeContext(ofAll: request.db)
            return try await request.view.render("FlashcardExample/FlashcardExamplePage", context)
        }
    }
    
}

struct MistExamplesIndexPage: HTMLDocument {
    
    let title = "Mist Examples"
    var head: some HTML {
        link(.rel(.stylesheet), .href("/mistexamples.css"))
    }
    
    var body: some HTML {
        main(.class("container")) {
            h1 { "Mist Examples" }
            ul {
                li { a(.href("/FlashcardExample")) { "Flashcard Example" } }
                li { a(.href("/CounterExample")) { "Counter Example" } }
            }
        }
    }
    
}
