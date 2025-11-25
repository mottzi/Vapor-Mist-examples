import Vapor
import Fluent
import Mist

final class MistDemoModel2: Mist.Model, Content, @unchecked Sendable
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

extension MistDemoModel2
{
    struct Table: AsyncMigration
    {
        func prepare(on database: Database) async throws
        {
            try await database.schema(MistDemoModel2.schema)
                .id()
                .field("text", .string, .required)
                .field("created", .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws
        {
            try await database.schema(MistDemoModel2.schema).delete()
        }
    }
}
