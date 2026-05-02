import Vapor
import VaporElementary

extension Application {
    func useMistDemo() {
        self.get("test") { _ in
            return "test4"
        }

//        self.get("MistDemo") { request async throws -> View in
//            let context = try await MistDemoComponent().makeContext(ofAll: request.db)
//            return try await request.view.render("MistDemo/MistDemoPanel", context)
//        }
        
        self.get("example") { _ in
            HTMLResponse {
                MainPage()
            }
        }
    }
}

struct MainPage: HTMLDocument {
    var title = "Elementary"

    var head: some HTML {
        meta(.name(.description), .content("Typesafe HTML in modern Swift"))
    }

    var body: some HTML {
        main {
            CounterComponent().body(state: CounterComponent.State())
        }
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}

import Mist
import Elementary

struct CounterComponent: ManualComponent {
    // Defines the shape of our globally shared state
    struct State: ComponentData {
        var count = 0
    }
    
    // The actor isolating the shared state
    let state = LiveState(of: State())
    
    // Actions exposed to the client
    var actions: [any Action] {
        [IncrementAction(counterState: state)]
    }

    // Natively render using Elementary DSL
    func body(state: State) -> some HTML {
        div(.mistComponent(value: name)) {
            h1 { "Global Count: \(state.count)" }
            button(.init(name: "mist-action", value: "increment")) { "Increment" }
        }
    }
}

struct IncrementAction: Action {
    let name = "increment"
    let counterState: LiveState<CounterComponent.State>
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        // Read current shared state
        let currentCount = await counterState.current.count
        
        // Mutate and broadcast to all connected clients
        await counterState.set(.init(count: currentCount + 1))
        
        return .success()
    }
}
