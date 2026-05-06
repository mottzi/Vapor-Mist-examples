import Vapor
import Fluent
import Mist

final class Scoreboard: Mist.Model, Content, @unchecked Sendable {
    static let schema = "sports_scoreboards"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "home_score")
    var homeScore: Int

    @Field(key: "away_score")
    var awayScore: Int

    @Field(key: "period")
    var period: String // e.g., "1st", "2nd", "Full Time"

    @Field(key: "is_live")
    var isLive: Bool

    init() {}

    init(id: UUID? = nil, homeScore: Int = 0, awayScore: Int = 0, period: String = "Upcoming", isLive: Bool = false) {
        self.id = id
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.period = period
        self.isLive = isLive
    }
}

extension Scoreboard {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Scoreboard.schema)
                .id()
                .field("home_score", .int, .required)
                .field("away_score", .int, .required)
                .field("period", .string, .required)
                .field("is_live", .bool, .required)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Scoreboard.schema).delete()
        }
    }
}
