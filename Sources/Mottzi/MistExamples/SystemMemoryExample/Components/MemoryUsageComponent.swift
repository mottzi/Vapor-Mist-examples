import Vapor
import Mist
import Elementary

struct MemoryUsageComponent: LiveComponent {

    struct State: ComponentData {
        var memoryUsage: Int
    }

    let state = LiveState(of: State(memoryUsage: getSystemMemoryUsageMB()))

    var refreshInterval: Duration { .seconds(2) }

    func refresh(app: Application) async {
        await state.set(State(memoryUsage: getSystemMemoryUsageMB()))
    }

    func body(state: State) -> some HTML {
        div(
            .mistComponent(name),
            .class("card stack text-center max-w-sm"),
            .style("flex: 1; min-width: 280px;")
        ) {
            div(.class("stack"), .style("gap: 0.5rem; align-items: center;")) {
                h2(.style("margin: 0;")) { "Memory Usage" }
            }
            div(.class("text-huge")) {
                "\(state.memoryUsage) MB"
            }
        }
    }
}
