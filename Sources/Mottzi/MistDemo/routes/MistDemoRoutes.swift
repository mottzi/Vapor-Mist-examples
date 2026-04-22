import Vapor

extension Application {
    func useMistDemo() {
        self.get("test") { _ in
            return "test2"
        }

        self.get("MistDemo") { request async throws -> View in
            let context = await MistDemoComponent().makeContext(ofAll: request.db)
            return try await request.view.render("MistDemo/MistDemoPanel", context)
        }
    }
}
