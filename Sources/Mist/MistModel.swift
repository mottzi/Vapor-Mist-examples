import Vapor
import Fluent
import Logging

public protocol Model: Fluent.Model where IDValue == UUID
{
    func contextExtras() -> [String: any Encodable]
}

public extension Model
{
    func contextExtras() -> [String: any Encodable]
    {
        return [:]
    }
    
    static func find(id: UUID, on database: Database) async -> (any Model)?
    {
        return try? await Self.find(id, on: database)
    }
    
    static func findAll(on database: Database) async -> [any Model]?
    {
        return try? await Self.query(on: database).all()
    }
}

public struct ModelContainer: Encodable
{
    let logger = Logger(label: "Mist.ModelContainer")
    
    private var models: [String: any Model] = [:]
    
    // [NEW] Metadata storage for ClientInteractive properties
    private var metadata: [String: AnyEncodable] = [:]
    
    var hasElements: Bool
    {
        !models.isEmpty
    }

    public mutating func add<M: Model>(_ model: M, for key: String)
    {
        models[key] = model
    }
    
    // [NEW] Helper to inject raw encodables
    public mutating func addMeta(_ value: any Encodable, for key: String) 
    {
        metadata[key] = AnyEncodable(value)
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        
        // Encode Models
        for (key, value) in models
        {
            let extras = value.contextExtras()
            
            if extras.isEmpty
            {
                try container.encode(value, forKey: StringCodingKey(key))
            }
            else
            {
                let wrapper = MergingEncoder(base: value, extras: extras)
                try container.encode(wrapper, forKey: StringCodingKey(key))
            }
        }
        
        // [NEW] Encode Metadata (e.g. _mistState, _mistLogic)
        for (key, value) in metadata 
        {
            try container.encode(value, forKey: StringCodingKey(key))
        }
    }
    
    public init() {}
}

public struct SingleComponentContext: Encodable
{
    public let component: ModelContainer
    
    public init(component: ModelContainer)
    {
        self.component = component
    }
}

public struct MultipleComponentContext: Encodable
{
    public let components: [ModelContainer]
    
    public init(components: [ModelContainer])
    {
        self.components = components
    }
    
    public static var empty: MultipleComponentContext
    {
        .init(components: [])
    }
}
