import Vapor

enum Message: Codable
{
    case text(message: String)
    
    case subscribe(component: String)

    case create(component: String, id: UUID, html: String)
    
    case update(component: String, id: UUID, html: String)
    
    case delete(component: String, id: UUID)
    
    case action(component: String, id: UUID, action: String)
    
    case actionResult(component: String, id: UUID, action: String, result: Mist.ActionResult, message: String)
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
    
    func broadcast(_ update: Message.Update) async
    {
        guard let jsonData = try? JSONEncoder().encode(update.wireFormat) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        for subscriber in subscribers(of: update.component)
        {
            Task { try? await subscriber.socket.send(jsonString) }
        }
    }
    
    func broadcast(_ deletion: Message.Delete) async
    {
        guard let jsonData = try? JSONEncoder().encode(deletion.wireFormat) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        for subscriber in subscribers(of: deletion.component)
        {
            Task { try? await subscriber.socket.send(jsonString) }
        }
    }

    func broadcast(_ creation: Message.Create) async
    {
        guard let jsonData = try? JSONEncoder().encode(creation.wireFormat) else { return }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        for subscriber in subscribers(of: creation.component)
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

    struct Create
    {
        let component: String
        let id: UUID
        let html: String
        
        var wireFormat: Message {
            .create(
                component: component, 
                id: id, 
                html: html
            )
        }
    }
    
    struct Update
    {
        let component: String
        let id: UUID
        let html: String
        
        var wireFormat: Message {
            .update(
                component: component,
                id: id,
                html: html
            )
        }
    }
    
    struct Delete
    {
        let component: String
        let id: UUID
        
        var wireFormat: Message {
            .delete(
                component: component,
                id: id
            )
        }
    }
    
    struct ActionResult
    {
        let component: String
        let id: UUID
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
