import Vapor
import Fluent
import Mist

final class MistDemoModel1: Mist.Model, Content, @unchecked Sendable
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
}

extension MistDemoModel1
{
    static func findAll(on database: Database) async -> [any Mist.Model]?
    {
        guard let models = try? await MistDemoModel1.query(on: database)
            .sort(\.$created, .descending)
            .all()
        else { return nil }
        return models
    }
    
    var shortID: String
    {
        String(id?.uuidString.prefix(8) ?? "")
    }
    
    var contextExtras: [String: any Encodable]
    {
        [
            "shortID": shortID
        ]
    }
}

extension MistDemoModel1
{
    struct Table: AsyncMigration
    {
        func prepare(on database: Database) async throws
        {
            try await database.schema(MistDemoModel1.schema)
                .id()
                .field("text", .string, .required)
                .field("created", .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws
        {
            try await database.schema(MistDemoModel1.schema).delete()
        }
    }
}
