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
//    var template: any Template { LeafTemplate.inline(
//        """
//        <div mist-component="CounterComponent">
//            <h2>Global Count</h2>
//            <div>#(count)</div>
//            <button mist-action="increment">Increment Count</button>
//        </div>
//        """
//    )}
    
    var actions: [any Action] {
        [
            IncrementAction(counterState: state)
        ]
    }
}

struct IncrementAction: Action {
    
    let name = "increment"
    let counterState: LiveState<CounterState>
    
    // Called when... to..., (optional: resulting in...).
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        
        let currentCount = await counterState.current.count
        await counterState.set(.init(count: currentCount + 1))
        return .success()
    }
}
