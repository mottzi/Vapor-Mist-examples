import Vapor

enum ClientMessage: Codable 
{
    case subscribe(component: String)
    case action(component: String, id: UUID?, action: String)
}

enum ServerMessage: Codable 
{
    case actionResult(component: String, id: UUID?, action: String, result: Mist.ActionResult, message: String)
    case text(message: String)
}

enum ServerBroadcast: Codable 
{
    case instanceComponent(ComponentBroadcast)
    case queryComponent(QueryComponentBroadcast)
}

enum ComponentBroadcast: Codable {
    case create(component: String, id: UUID, html: String)
    case update(component: String, id: UUID, html: String)
    case delete(component: String, id: UUID)
}

enum QueryComponentBroadcast: Codable {
    case upsert(component: String, html: String) // Renamed from 'create' for clarity
    case delete(component: String)
}

extension Clients
{
    func send(_ message: String, to clientID: UUID) async
    {
        let event = ServerMessage.text(message: message)
        await send(event, to: clientID)
    }

    func send(_ event: ServerMessage, to clientID: UUID) async
    {
        guard let client = clients.first(where: { $0.id == clientID }) else { return }
        guard let jsonData = try? JSONEncoder().encode(event) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        try? await client.socket.send(jsonString)
    }

    func broadcast(_ message: ComponentBroadcast) async
    {
        await broadcast(.instanceComponent(message))
    }

    func broadcast(_ message: QueryComponentBroadcast) async
    {
        await broadcast(.queryComponent(message))
    }

    private func broadcast(_ message: ServerBroadcast) async
    {
        guard let jsonData = try? JSONEncoder().encode(message) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        let componentName = message.componentName

        for subscriber in subscribers(of: componentName)
        {
            Task { try? await subscriber.socket.send(jsonString) }
        }
    }
}

extension ServerBroadcast 
{
    var componentName: String 
    {
        switch self 
        {
            case .instanceComponent(let message): return switch message 
            {
                case .create(let component, _, _): component
                case .update(let component, _, _): component
                case .delete(let component, _): component
            }
            case .queryComponent(let message): return switch message
            {
                case .upsert(let component, _): component
                case .delete(let component): component
            }
        }
    }
}