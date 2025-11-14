import Vapor
import Fluent
import Leaf
import LeafKit

public struct Socket
{
    func register(on app: Application)
    {
        app.webSocket("mist", "ws") { request, ws async in
            await Connection(app: request.application, ws: ws).onUpgrade()
        }
    }
}

extension Socket.Connection
{
    func onUpgrade() async
    {
        await app.mist.clients.addClient(id: clientID, socket: ws)
        await app.mist.clients.send("Client (\(clientID.short)) was registered.", to: clientID)

        ws.onText() { ws, text async in
            Task { await onText(text) }
        }

        ws.onClose.whenComplete() { _ in
            Task { await app.mist.clients.removeClient(id: clientID) }
        }
    }

    func onText(_ text: String) async
    {
        guard let data = text.data(using: .utf8) else { return }
        guard let message = try? JSONDecoder().decode(ClientMessage.self, from: data) else { return }

        switch message
        {
            case .subscribe(let component):
                await handleSubscribe(component)

            case .action(let component, let id, let action):
                await handleAction(component, id, action)
        }
    }

    func handleSubscribe(_ component: String) async
    {
        let success = await app.mist.clients.addSubscription(component, to: clientID)
        let response = success
            ? "Client (\(clientID.short)) subscribed to component '\(component)'."
            : "Client (\(clientID.short)) didn't subscribe to component '\(component)'."
        await app.mist.clients.send(response, to: clientID)
    }

    func handleAction(_ component: String, _ id: UUID?, _ action: String) async
    {
        let result = await app.mist.components.performAction(
            component: component,
            action: action,
            id: id,
            on: app.db
        )

        let resultMessage = switch result {
            case .success(let message): message ?? "Success"
            case .failure(let message): message ?? "Failure"
        }

        let event = ServerMessage.actionResult(component: component, id: id, action: action, result: result, message: resultMessage)
        await app.mist.clients.send(event, to: clientID)
    }

}

extension Socket 
{
    struct Connection
    {
        let app: Application
        let ws: WebSocket
        let clientID: UUID

        @discardableResult
        init(app: Application, ws: WebSocket)
        {
            self.app = app
            self.ws = ws
            self.clientID = UUID()
        }
    }   
}

extension UUID
{
    var short: String { return String(uuidString.prefix(8)) }
}