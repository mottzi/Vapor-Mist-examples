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
    case instanceComponent(ComponentMessage)
    case queryComponent(QueryComponentMessage)
}

enum ComponentMessage: Codable {
    case create(component: String, id: UUID, html: String)
    case update(component: String, id: UUID, html: String)
    case delete(component: String, id: UUID)
    
    enum CodingKeys: String, CodingKey {
        case create, update, delete
    }
    
    struct ComponentPayload: Codable {
        let component: String
        let id: UUID
        let html: String
    }
    
    struct DeletePayload: Codable {
        let component: String
        let id: UUID
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .create(let component, let id, let html):
            try container.encode(ComponentPayload(component: component, id: id, html: html), forKey: .create)
        case .update(let component, let id, let html):
            try container.encode(ComponentPayload(component: component, id: id, html: html), forKey: .update)
        case .delete(let component, let id):
            try container.encode(DeletePayload(component: component, id: id), forKey: .delete)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(ComponentPayload.self, forKey: .create) {
            self = .create(component: value.component, id: value.id, html: value.html)
        } else if let value = try? container.decode(ComponentPayload.self, forKey: .update) {
            self = .update(component: value.component, id: value.id, html: value.html)
        } else if let value = try? container.decode(DeletePayload.self, forKey: .delete) {
            self = .delete(component: value.component, id: value.id)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown case"))
        }
    }
}

enum QueryComponentMessage: Codable {
    case upsert(component: String, html: String)
    case delete(component: String)
    
    enum CodingKeys: String, CodingKey {
        case upsert, delete
    }
    
    struct UpsertPayload: Codable {
        let component: String
        let html: String
    }
    
    struct DeletePayload: Codable {
        let component: String
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .upsert(let component, let html):
            try container.encode(UpsertPayload(component: component, html: html), forKey: .upsert)
        case .delete(let component):
            try container.encode(DeletePayload(component: component), forKey: .delete)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(UpsertPayload.self, forKey: .upsert) {
            self = .upsert(component: value.component, html: value.html)
        } else if let value = try? container.decode(DeletePayload.self, forKey: .delete) {
            self = .delete(component: value.component)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown case"))
        }
    }
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

    func broadcast(_ message: ComponentMessage) async
    {
        await broadcast(.instanceComponent(message))
    }

    func broadcast(_ message: QueryComponentMessage) async
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