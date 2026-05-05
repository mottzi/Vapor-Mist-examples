import Vapor
import Fluent
import Mist

struct ProfileComponent: InstanceComponent {

    let division: String

    var name: String { Self.name(for: division) }

    let models: [any Mist.Model.Type] = [User.self, Profile.self]

    let template: any Template = LeafTemplate.file("TeamProfileExample/ProfileComponent")

    static func name(for division: String) -> String {
        "ProfileComponent-\(division)"
    }

    func allModels(on db: Database) async throws -> [any Mist.Model] {
        try await User.query(on: db)
            .filter(\.$division == division)
            .sort(\.$displayName)
            .all()
    }
}

extension ProfileComponent {

    func shouldUpdate<M: Fluent.Model>(for model: M) -> Bool {
        if let user = model as? User {
            return user.division == division
        }
        if let profile = model as? Profile {
            return profile.division == division
        }
        return false
    }
}
