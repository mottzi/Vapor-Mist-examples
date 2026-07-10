import Vapor

// This is the Swift app that Deployer will manage.

extension Application {

    func registerTestRoute() {
  
        // This is the test route to demo code changes going live.

        self.get("test") { _ in
            """
            4nn
            """
        }
        
    }

}
