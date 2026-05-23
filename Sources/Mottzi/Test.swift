import Vapor

extension Application {

    func registerTestRoute() {
  
        self.get("test") { _ in
            "Hello, World!"
        }

    }

}