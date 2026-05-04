import Vapor
import Mist
import Elementary
import Foundation

struct CpuLoadComponent: LiveComponent {

    struct State: ComponentData {
        var cpuLoad: Double
    }

    let state = LiveState(of: State(cpuLoad: getSystemLoadAverage()))

    var refreshInterval: Duration { .seconds(2) }

    func refresh(app: Application) async {
        await state.set(State(cpuLoad: getSystemLoadAverage()))
    }

    func body(state: State) -> some HTML {
        div(
            .mistComponent(name),
            .class("card stack text-center max-w-sm"),
            .style("flex: 1; min-width: 280px;")
        ) {
            div(.class("stack"), .style("gap: 0.5rem; align-items: center;")) {
                h2(.style("margin: 0;")) { "System Load" }
            }
            div(.class("text-huge")) {
                "\(String(format: "%.2f", state.cpuLoad))"
            }
        }
    }
}
