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
            .class("card metric-card stack text-center")
        ) {
            div(.class("stack component-heading")) {
                h2 { "System load" }
            }
            div(.class("text-huge")) {
                "\(String(format: "%.2f", state.cpuLoad))"
            }
        }
    }
}
