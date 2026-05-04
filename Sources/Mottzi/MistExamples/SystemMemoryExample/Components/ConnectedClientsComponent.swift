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
            .mistComponent(value: name),
            .class("card stack text-center max-w-sm"),
            .style("flex: 1; min-width: 280px;")
        ) {
            div(.class("stack"), .style("gap: 0.5rem; align-items: center;")) {
                h2(.style("margin: 0;")) { "Connected Clients" }
            }
            div(.class("text-huge")) {
                "\(state.clientCount)"
            }
        }
    }
}
