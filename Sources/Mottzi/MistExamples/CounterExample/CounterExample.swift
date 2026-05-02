import Vapor
import Mist
import Elementary

struct CounterExamplePage: HTMLDocument {
    var title = "Counter Example"

    var head: some HTML {
        meta(.name(.description), .content("Typesafe HTML in modern Swift"))
        link(.rel(.stylesheet), .href("/mistexamples.css"))
    }

    var body: some HTML {
        
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            CounterExampleComponent()
                .body(state: CounterExampleComponent.State())
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}

struct CounterExampleComponent: ManualComponent {

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
    let counterState: LiveState<CounterExampleComponent.State>
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {

        let currentCount = await counterState.current.count
        await counterState.set(.init(count: currentCount + 1))
        
        return .success()
    }
}
