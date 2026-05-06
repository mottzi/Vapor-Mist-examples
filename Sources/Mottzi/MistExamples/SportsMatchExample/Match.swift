import Vapor
import Fluent
import Mist

final class Match: Mist.Model, Content, @unchecked Sendable {
    static let schema = "sports_matches"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "home_team")
    var homeTeam: String

    @Field(key: "away_team")
    var awayTeam: String

    @Field(key: "venue")
    var venue: String

    @Field(key: "kickoff_at")
    var kickoffAt: Date

    init() {}

    init(id: UUID? = nil, homeTeam: String, awayTeam: String, venue: String, kickoffAt: Date) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.venue = venue
        self.kickoffAt = kickoffAt
    }
}

extension Match {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Match.schema)
                .id()
                .field("home_team", .string, .required)
                .field("away_team", .string, .required)
                .field("venue", .string, .required)
                .field("kickoff_at", .datetime, .required)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Match.schema).delete()
        }
    }
}
