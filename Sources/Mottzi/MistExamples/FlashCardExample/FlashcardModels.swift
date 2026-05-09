import Vapor
import Fluent
import Mist

final class FlashcardFrontModel: Mist.Model, Content, @unchecked Sendable {
    
    static let schema = "CardFront"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "text") var text: String
    
    @Timestamp(key: "created", on: .create) var created: Date?
    
    init() {}
    
    init(text: String) {
        self.text = text
    }
    
}

extension FlashcardFrontModel {
    
    struct Table: AsyncMigration {
        
        func prepare(on database: Database) async throws {
            
            try await database.schema(FlashcardFrontModel.schema)
                .id()
                .field("text", .string, .required)
                .field("created", .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(FlashcardFrontModel.schema).delete()
        }
    }
    
}

extension FlashcardFrontModel {
    
    static func findAll(on database: Database) async -> [any Mist.Model]? {
        
        guard let models = try? await FlashcardFrontModel.query(on: database)
            .sort(\.$created, .descending)
            .all()
        else { return nil }
        return models
    }
    
    var shortID: String { String(id?.uuidString.prefix(8) ?? "") }
    
    var contextExtras: [String: any Encodable] {[ "shortID": shortID ]}
    
}


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
