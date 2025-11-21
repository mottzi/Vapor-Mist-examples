import Vapor

extension Application
{
    func useMistDemo()
    {
        self.get("test") { _ in
            return "Hello, World!"
        }
        
        self.get("mistDemo")
        { request async throws -> View in
            let context = await MistDemoComponent().makeContext(ofAll: request.db)
            
            return try await request.view.render("mistDemo/MistDemoPanel", context)
        }
        
        self.get("DemoModel1", "update", ":id", ":text")
        { req async throws -> HTTPStatus in
            guard let idString = req.parameters.get("id"),
                  let id = UUID(uuidString: idString)
            else { throw Abort(.badRequest, reason: "Valid UUID parameter is required") }
            
            guard let text = req.parameters.get("text")
            else { throw Abort(.badRequest, reason: "Valid text parameter is required") }
            
            guard let demoModel1 = try await MistDemoModel1.find(id, on: req.db)
            else { throw Abort(.notFound, reason: "DemoModel1 with specified ID not found") }
            
            demoModel1.text = text
            try await demoModel1.save(on: req.db)
            
            return .ok
        }
        
        self.get("DemoModel2", "update", ":id", ":text")
        { req async throws -> HTTPStatus in
            guard let idString = req.parameters.get("id"),
                  let id = UUID(uuidString: idString)
            else { throw Abort(.badRequest, reason: "Valid UUID parameter is required") }
            
            guard let text = req.parameters.get("text")
            else { throw Abort(.badRequest, reason: "Valid text parameter is required") }
            
            guard let demoModel2 = try await MistDemoModel2.find(id, on: req.db)
            else { throw Abort(.notFound, reason: "DemoModel2 with specified ID not found") }
            
            demoModel2.text = text
            try await demoModel2.save(on: req.db)
            
            return .ok
        }
        
        self.get("DemoModels", "delete", ":id")
        { req async throws -> HTTPStatus in
            guard let idString = req.parameters.get("id"),
                  let id = UUID(uuidString: idString)
            else { throw Abort(.badRequest, reason: "Valid UUID parameter is required") }
            
            guard let demoModel1 = try await MistDemoModel1.find(id, on: req.db)
            else { throw Abort(.notFound, reason: "DemoModel1 with specified ID not found") }
            
            guard let demoModel2 = try await MistDemoModel2.find(id, on: req.db)
            else { throw Abort(.notFound, reason: "DemoModel2 with specified ID not found") }
            
            try await demoModel1.delete(on: req.db)
            try await demoModel2.delete(on: req.db)
            
            return .ok
        }
        
        self.get("DemoModels", "deleteAll")
        { req async throws -> HTTPStatus in
            try await MistDemoModel1.query(on: req.db).delete()
            try await MistDemoModel2.query(on: req.db).delete()
            return .ok
        }
        
        self.get("DemoModels", "create")
        { req async throws -> MistDemoModel1 in
            let words =
            [
                "swift", "vapor", "fluent", "leaf", "websocket", "async",
                "database", "server", "client", "model", "view", "controller",
                "route", "middleware", "protocol", "actor", "request", "response"
            ]
            
            let demoModel1 = MistDemoModel1(text: words.randomElement() ?? "error")
            try await demoModel1.save(on: req.db)
            
            let demoModel2 = MistDemoModel2(text: words.randomElement() ?? "error")
            demoModel2.id = demoModel1.id
            try await demoModel2.save(on: req.db)
            
            return demoModel1
        }
    }
}

