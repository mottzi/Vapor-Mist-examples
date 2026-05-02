import Vapor
import Fluent
import Mist

final class FlashcardBackModel: Mist.Model, Content, @unchecked Sendable {
    
    static let schema = "CardBack"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "text") var text: String
    
    @Timestamp(key: "created", on: .create) var created: Date?
    
    init() {}
    
    init(text: String) {
        self.text = text
    }
    
}

extension FlashcardBackModel {
    
    struct Table: AsyncMigration {
        
        func prepare(on database: Database) async throws {
            
            try await database.schema(FlashcardBackModel.schema)
                .id()
                .field("text", .string, .required)
                .field("created", .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(FlashcardBackModel.schema).delete()
        }
    }
    
}
