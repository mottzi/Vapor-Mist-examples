import Vapor
import Fluent
import Mist

final class LiveVotingModel: Mist.Model, Content, @unchecked Sendable {
    
    static let schema = "PollVotes"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "choice") var choice: String
    
    init() {}
    init(choice: String) { self.choice = choice }
}

extension LiveVotingModel {
    
    struct Table: AsyncMigration {
        
        func prepare(on database: Database) async throws {
            
            try await database.schema(LiveVotingModel.schema)
                .id()
                .field("choice", .string, .required)
                .create()
        }
        
        func revert(on database: Database) async throws {
            
            try await database.schema(LiveVotingModel.schema).delete()
        }
    }
}
