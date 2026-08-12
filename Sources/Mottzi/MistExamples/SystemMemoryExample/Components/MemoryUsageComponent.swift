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
            .class("card metric-card stack text-center")
        ) {
            div(.class("stack component-heading")) {
                h2 { "Memory" }
            }
            div(.class("text-huge")) {
                "\(state.memoryUsage) MB"
            }
        }
    }
}
