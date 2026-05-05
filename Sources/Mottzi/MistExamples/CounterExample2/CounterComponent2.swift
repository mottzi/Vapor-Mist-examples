import Vapor
import Mist

struct CounterComponent2: ManualComponent {
    
    let state = LiveState(of: CounterState())
    
    let template: Mist.Template = LeafTemplate.file("CounterExample2/CounterComponent2")
    
    var actions: [any Action] { [ IncrementAction2(counterState: state) ] }
}

struct IncrementAction2: Action {
    
    let name = "increment"
    let counterState: LiveState<CounterState>
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        
        let currentCount = await counterState.current.count
        await counterState.set(.init(count: currentCount + 1))
        return .success()
    }
}
