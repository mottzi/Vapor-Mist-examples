import Fluent
import Vapor
import Mist

struct SportsMatchSeed: AsyncMigration {
    func prepare(on database: Database) async throws {
        let matches = [
            ("Real Madrid", "Barcelona", "Santiago Bernabéu"),
            ("Man City", "Arsenal", "Etihad Stadium"),
            ("Bayern Munich", "Dortmund", "Allianz Arena")
        ]
        
        for (home, away, venue) in matches {
            let id = UUID()
            let match = Match(id: id, homeTeam: home, awayTeam: away, venue: venue, kickoffAt: Date())
            try await match.save(on: database)
            
            let scoreboard = Scoreboard(id: id, homeScore: 0, awayScore: 0, period: "Upcoming", isLive: false)
            try await scoreboard.save(on: database)
        }
    }

    func revert(on database: Database) async throws {
        try await Scoreboard.query(on: database).delete()
        try await Match.query(on: database).delete()
    }
}
