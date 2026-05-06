import Vapor
import Fluent
import Mist

struct MatchComponent: InstanceComponent {
    let name: String = "MatchComponent"
    let models: [any Mist.Model.Type] = [Match.self, Scoreboard.self]
    let actions: [any Mist.Action] = [HomeGoalAction(), AwayGoalAction(), ChangePeriodAction(), ResetMatchAction()]
    let template: Mist.Template = LeafTemplate.file("SportsMatchExample/MatchComponent")

    func allModels(on db: Database) async throws -> [any Mist.Model] {
        try await Match.query(on: db).sort(\.$kickoffAt).all().map { $0 as any Mist.Model }
    }
}

// MARK: - Actions

struct HomeGoalAction: Mist.Action {
    let name: String = "homeGoal"
    func perform(targetID id: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        guard let id, let scoreboard = try? await Scoreboard.find(id: id, on: app.db) as? Scoreboard else { return .failure("NotFound") }
        scoreboard.homeScore += 1
        scoreboard.isLive = true
        try? await scoreboard.save(on: app.db)
        return .success()
    }
}

struct AwayGoalAction: Mist.Action {
    let name: String = "awayGoal"
    func perform(targetID id: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        guard let id, let scoreboard = try? await Scoreboard.find(id: id, on: app.db) as? Scoreboard else { return .failure("NotFound") }
        scoreboard.awayScore += 1
        scoreboard.isLive = true
        try? await scoreboard.save(on: app.db)
        return .success()
    }
}

struct ChangePeriodAction: Mist.Action {
    let name: String = "nextPeriod"
    func perform(targetID id: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        guard let id, let scoreboard = try? await Scoreboard.find(id: id, on: app.db) as? Scoreboard else { return .failure("NotFound") }
        
        let periods = ["Upcoming", "1st Half", "Halftime", "2nd Half", "Full Time"]
        if let currentIdx = periods.firstIndex(of: scoreboard.period), currentIdx < periods.count - 1 {
            scoreboard.period = periods[currentIdx + 1]
        } else {
            scoreboard.period = periods[0]
        }
        
        scoreboard.isLive = (scoreboard.period.contains("Half"))
        try? await scoreboard.save(on: app.db)
        return .success()
    }
}

struct ResetMatchAction: Mist.Action {
    let name: String = "reset"
    func perform(targetID id: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        guard let id, let scoreboard = try? await Scoreboard.find(id: id, on: app.db) as? Scoreboard else { return .failure("NotFound") }
        scoreboard.homeScore = 0
        scoreboard.awayScore = 0
        scoreboard.period = "Upcoming"
        scoreboard.isLive = false
        try? await scoreboard.save(on: app.db)
        return .success()
    }
}
