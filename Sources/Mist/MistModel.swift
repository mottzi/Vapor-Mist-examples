import Vapor
import Fluent
import Logging

public protocol Model: Fluent.Model where IDValue == UUID
{
    func contextExtras() -> [String: any Encodable]
    static func findAll(on database: Database) async -> [any Model]?
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
    private var models: [String: any Model] = [:]
    
    var hasElements: Bool {
        return !models.isEmpty
    }

    public mutating func add<M: Model>(_ model: M, for key: String) {
        models[key] = model
    }
    
    // flattens the models dictionary when encoding, making properties directly accessible in template
    public func encode(to encoder: Encoder) throws
    {
        let logger = Logger(label: "Mist.ModelContainer")
        
        var container = encoder.container(keyedBy: StringCodingKey.self)
        
        for (key, value) in models
        {
            // Get extras from the model via protocol method
            let extras = value.contextExtras()
            
            if extras.isEmpty
            {
                // direct encoding
                logger.warning("Encoding model '\(key)' (type: \(type(of: value))) without extras")
                try container.encode(value, forKey: StringCodingKey(key))
            }
            else
            {
                // merge extras
                logger.warning("Encoding model '\(key)' (type: \(type(of: value))) with \(extras.count) extras: \(extras.keys.sorted())")
                let wrapper = MergingEncoder(base: value, extras: extras)
                try container.encode(wrapper, forKey: StringCodingKey(key))
            }
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
