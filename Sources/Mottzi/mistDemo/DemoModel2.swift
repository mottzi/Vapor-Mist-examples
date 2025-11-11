import Vapor
import Fluent
import Mist

final class DemoModel2: Mist.Model, Content, @unchecked Sendable
{
    static let schema = "DemoModel2"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "text") var text: String
    @Timestamp(key: "created", on: .create) var created: Date?
    
    init() {}
    
    init(text: String)
    {
        self.text = text
    }
}

extension DemoModel2
{
    static var findAll: (Database) async -> [any Mist.Model]?
    {
        return { db in
            guard let models = try? await DemoModel2.query(on: db)
                .sort(\.$created, .descending)
                .all()
            else { return nil }
            return models
        }
    }
}

// database table
extension DemoModel2
{
    struct Table: AsyncMigration
    {
        func prepare(on database: Database) async throws
        {
            try await database.schema(DemoModel2.schema)
                .id()
                .field("text", .string, .required)
                .field("created", .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws
        {
            try await database.schema(DemoModel2.schema).delete()
        }
    }
}
