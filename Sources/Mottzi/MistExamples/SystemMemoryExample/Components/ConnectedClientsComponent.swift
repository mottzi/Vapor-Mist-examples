import Vapor
import Mist
import Elementary

struct ConnectedClientsComponent: LiveComponent {

    struct State: ComponentData {
        var clientCount: Int
    }

    let state = LiveState(of: State(clientCount: 0))

    var refreshInterval: Duration { .seconds(2) }

    func refresh(app: Application) async {
        await state.set(State(clientCount: await app.mist.clients.count))
    }

    func body(state: State) -> some HTML {
        div(
            .mistComponent(name),
            .class("card metric-card stack text-center")
        ) {
            div(.class("stack component-heading")) {
                h2 { "Connected clients" }
            }
            div(.class("text-huge")) {
                "\(state.clientCount)"
            }
        }
    }
}
