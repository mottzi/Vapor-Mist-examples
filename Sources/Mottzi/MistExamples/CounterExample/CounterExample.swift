import Vapor
import Mist
import Elementary

struct CounterExamplePage: HTMLDocument {
    var title = "Counter Example"

    var head: some HTML {
        meta(.name(.description), .content("Typesafe HTML in modern Swift"))
    }

    var body: some HTML {
        main {
            CounterExampleComponent()
                .body(state: CounterExampleComponent.State())
        }
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}

struct CounterExampleComponent: ManualComponent {
    // Defines the shape of our globally shared state
    struct State: ComponentData { var count = 0 }
    
    // The actor isolating the shared state
    let state = LiveState(of: State())
    
    // Actions exposed to the client
    var actions: [any Action] { [IncrementAction(counterState: state)] }

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
    let counterState: LiveState<CounterExampleComponent.State>
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        // Read current shared state
        let currentCount = await counterState.current.count
        
        // Mutate and broadcast to all connected clients
        await counterState.set(.init(count: currentCount + 1))
        
        return .success()
    }
}
