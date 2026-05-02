import Vapor
import VaporElementary

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
