import Vapor
import Fluent
import Mist

/// Shares its primary key with `User`. `division` is duplicated so `shouldUpdate` can filter without async lookups.
final class Profile: Mist.Model, Content, @unchecked Sendable {

    static let schema = "team_profile_profiles"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "bio")
    var bio: String

    @Field(key: "division")
    var division: String

    init() {}

    init(id: UUID? = nil, bio: String, division: String) {
        self.id = id
        self.bio = bio
        self.division = division
    }
}

extension Profile {

    struct Table: AsyncMigration {

        func prepare(on database: Database) async throws {
            try await database.schema(Profile.schema)
                .id()
                .field("bio", .string, .required)
                .field("division", .string, .required)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Profile.schema).delete()
        }
    }
}
