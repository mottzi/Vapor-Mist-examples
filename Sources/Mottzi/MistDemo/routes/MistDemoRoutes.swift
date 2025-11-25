import Vapor

extension Application {
    func useMistDemo() {
        self.get("test") { _ in
            return "4133"
        }

        self.get("mistDemo") { request async throws -> View in
            let context = await MistDemoComponent().makeContext(ofAll: request.db)

            return try await request.view.render("mistDemo/MistDemoPanel", context)
        }
    }
}
