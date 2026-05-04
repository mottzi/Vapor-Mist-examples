import Vapor
import Mist
import Elementary

struct CounterState: ComponentData {
    var count = 0
}

struct CounterComponent: ManualComponent {
    
    let state = LiveState(of: CounterState())

    func body(state: CounterState) -> some HTML {
        
        div(
            .mistComponent(value: name),
            .class("card stack text-center mx-auto max-w-sm")
        ) {
            div(.class("stack"), .style("gap: 0.5rem; align-items: center;")) {
                span(.class("badge")) { "ManualComponent" }
                h2(.style("margin: 0;")) { "Count" }
            }
            div(.class("text-huge")) {
                "\(state.count)"
            }
            button(.mistAction(value: "increment"), .class("btn-primary mt-4")) {
                "Increment"
            }
        }
    }
    
    var actions: [any Action] {
        [
            IncrementAction(counterState: state)
        ]
    }
}

struct IncrementAction: Action {
    
    let name = "increment"
    let counterState: LiveState<CounterState>
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        
        let currentCount = await counterState.current.count
        await counterState.set(.init(count: currentCount + 1))
        return .success()
    }
}