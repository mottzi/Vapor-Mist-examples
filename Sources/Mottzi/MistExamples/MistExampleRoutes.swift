import Vapor
import VaporElementary

extension Application {
    func useMistExamples() {
        self.get("test") { _ in
            "test4"
        }

        self.get("FlashcardExample") { request async throws -> View in
            let context = try await FlashcardComponent().makeContext(ofAll: request.db)
            return try await request.view.render("FlashcardExample/FlashcardPanel", context)
        }
        
        self.get("CounterExample") { _ in
            HTMLResponse {
                CounterExamplePage()
            }
        }
    }
}
