import Vapor

enum Message: Codable
{
    case text(message: String)

    case subscribe(component: String)

    // Instance-based components (with specific model IDs)
    case instanceCreate(component: String, id: UUID, html: String)
    case instanceUpdate(component: String, id: UUID, html: String)
    case instanceDelete(component: String, id: UUID)
    
    // Query-based components (singleton, no ID)
    case queryUpdate(component: String, html: String)
    case queryDelete(component: String)

    case action(component: String, id: UUID?, action: String)

    case actionResult(component: String, id: UUID?, action: String, result: Mist.ActionResult, message: String)
}

extension Clients
{
    func send(_ message: String, to clientID: UUID) async 
    {
        let message = Message.Text(message: message)
        await send(message, to: clientID)
    }

    func send(_ message: Message.Text, to clientID: UUID) async
    {
        guard let client = clients.first(where: { $0.id == clientID }) else { return }
        guard let jsonData = try? JSONEncoder().encode(message.wireFormat) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        try? await client.socket.send(jsonString)
    }
    
    func send(_ actionResult: Message.ActionResult, to clientID: UUID) async
    {
        guard let client = clients.first(where: { $0.id == clientID }) else { return }
        guard let jsonData = try? JSONEncoder().encode(actionResult.wireFormat) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        try? await client.socket.send(jsonString)
    }
    
    // Instance-based component broadcasts
    func broadcast(_ create: Message.InstanceCreate) async
    {
        guard let jsonData = try? JSONEncoder().encode(create.wireFormat) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        for subscriber in subscribers(of: create.component)
        {
            Task { try? await subscriber.socket.send(jsonString) }
        }
    }
    
    func broadcast(_ update: Message.InstanceUpdate) async
    {
        guard let jsonData = try? JSONEncoder().encode(update.wireFormat) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        for subscriber in subscribers(of: update.component)
        {
            Task { try? await subscriber.socket.send(jsonString) }
        }
    }
    
    func broadcast(_ delete: Message.InstanceDelete) async
    {
        guard let jsonData = try? JSONEncoder().encode(delete.wireFormat) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        for subscriber in subscribers(of: delete.component)
        {
            Task { try? await subscriber.socket.send(jsonString) }
        }
    }
    
    // Query-based component broadcasts
    func broadcast(_ update: Message.QueryUpdate) async
    {
        guard let jsonData = try? JSONEncoder().encode(update.wireFormat) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        for subscriber in subscribers(of: update.component)
        {
            Task { try? await subscriber.socket.send(jsonString) }
        }
    }
    
    func broadcast(_ delete: Message.QueryDelete) async
    {
        guard let jsonData = try? JSONEncoder().encode(delete.wireFormat) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        for subscriber in subscribers(of: delete.component)
        {
            Task { try? await subscriber.socket.send(jsonString) }
        }
    }
}

extension Message
{
    struct Text
    {
        let message: String
        
        var wireFormat: Message {
            .text(message: message)
        }
    }

    // Instance-based component message structs
    struct InstanceCreate
    {
        let component: String
        let id: UUID
        let html: String

        var wireFormat: Message {
            .instanceCreate(
                component: component,
                id: id,
                html: html
            )
        }
    }

    struct InstanceUpdate
    {
        let component: String
        let id: UUID
        let html: String

        var wireFormat: Message {
            .instanceUpdate(
                component: component,
                id: id,
                html: html
            )
        }
    }

    struct InstanceDelete
    {
        let component: String
        let id: UUID

        var wireFormat: Message {
            .instanceDelete(
                component: component,
                id: id
            )
        }
    }

    // Query-based component message structs
    struct QueryUpdate
    {
        let component: String
        let html: String

        var wireFormat: Message {
            .queryUpdate(
                component: component,
                html: html
            )
        }
    }

    struct QueryDelete
    {
        let component: String

        var wireFormat: Message {
            .queryDelete(
                component: component
            )
        }
    }

    struct ActionResult
    {
        let component: String
        let id: UUID?
        let action: String
        let result: Mist.ActionResult
        let message: String

        var wireFormat: Message {
            .actionResult(
                component: component,
                id: id,
                action: action,
                result: result,
                message: message
            )
        }
    }
}
