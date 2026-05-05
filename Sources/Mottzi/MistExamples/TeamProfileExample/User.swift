import Vapor
import Fluent
import Mist

enum TeamProfileExample {

    static let divisions = ["europe", "east-coast"]

}

final class User: Mist.Model, Content, @unchecked Sendable {

    static let schema = "team_profile_users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "division")
    var division: String

    @Field(key: "display_name")
    var displayName: String

    @Field(key: "handle")
    var handle: String

    init() {}

    init(id: UUID? = nil, division: String, displayName: String, handle: String) {
        self.id = id
        self.division = division
        self.displayName = displayName
        self.handle = handle
    }
}

extension User {

    struct Table: AsyncMigration {

        func prepare(on database: Database) async throws {
            try await database.schema(User.schema)
                .id()
                .field("division", .string, .required)
                .field("display_name", .string, .required)
                .field("handle", .string, .required)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(User.schema).delete()
        }
    }
}
