import Elementary
import Mist
import Vapor

struct CounterState: ComponentData {
    var count = 0
}

struct CounterComponent: ManualComponent {

    let state = LiveState(of: CounterState())

    // let template: Mist.Template = LeafTemplate.file("CounterExample/CounterComponent")

    func body(state: CounterState) -> some HTML {

        div(
            .mistComponent(name),
            .class("card counter-card stack text-center mx-auto max-w-sm")
        ) {
            div(.class("stack component-heading")) {
                h2 { "Current count" }
            }
            div(.class("text-huge")) {
                "\(state.count)"
            }
            button(.mistAction("increment"), .class("btn-primary mt-4")) {
                "Increment count"
            }
        }
    }

    var actions: [any Action] { [IncrementAction(counterState: state)] }
}

struct IncrementAction: Action {

    let name = "increment"
    let counterState: LiveState<CounterState>

    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async
        -> ActionResult
    {

        let currentCount = await counterState.current.count
        await counterState.set(.init(count: currentCount + 1))
        return .success()
    }
}
