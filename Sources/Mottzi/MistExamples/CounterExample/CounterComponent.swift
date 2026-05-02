import Vapor
import Mist
import Elementary

struct CounterComponent: ManualComponent {

    struct State: ComponentData { var count = 0 }
    
    let state = LiveState(of: State())
    
    var actions: [any Action] { [IncrementAction(counterState: state)] }

    func body(state: State) -> some HTML {
        
        div(
            .mistComponent(value: name),
            .class("card stack text-center mx-auto max-w-sm")
        ) {
            h2 {
                "Global Count"
            }
            div(.class("text-huge")) {
                "\(state.count)"
            }
            button(.mistAction(value: "increment")) {
                "Increment Count"
            }
        }
    }
}

struct IncrementAction: Action {
    
    let name = "increment"
    let counterState: LiveState<CounterComponent.State>
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {

        let currentCount = await counterState.current.count
        await counterState.set(.init(count: currentCount + 1))
        
        return .success()
    }
}
