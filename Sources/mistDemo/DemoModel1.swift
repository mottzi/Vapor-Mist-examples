import Vapor
import Fluent
import Mist

final class DemoModel1: Mist.Model, Content, @unchecked Sendable
{
    static let schema = "DemoModel1"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "text") var text: String
    @Timestamp(key: "created", on: .create) var created: Date?
    
    init() {}
    
    init(text: String)
    {
        self.text = text
    }
    
    var shortID: String
    {
        String(id?.uuidString.prefix(8) ?? "")
    }
}

extension DemoModel1
{
    enum CodingKeys: String, CodingKey
    {
        case id, text, created
        case shortID  // Add the computed property
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(created, forKey: .created)
        
        // Encode the computed property
        try container.encode(shortID, forKey: .shortID)
    }
}

extension DemoModel1
{
    static func all(on database: Database) async throws -> [DemoModel1]
    {
        try await DemoModel1.query(on: database)
            .sort(\.$created, .descending)
            .all()
    }
}

// database table
extension DemoModel1
{
    struct Table: AsyncMigration
    {
        func prepare(on database: Database) async throws
        {
            try await database.schema(DemoModel1.schema)
                .id()
                .field("text", .string, .required)
                .field("created", .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws
        {
            try await database.schema(DemoModel1.schema).delete()
        }
    }
}
