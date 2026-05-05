import Fluent
import Vapor

struct TeamProfileSeed: AsyncMigration {

    private let seededIDs: [UUID] = [
        UUID(uuidString: "11111111-1111-4111-8111-111111111101")!,
        UUID(uuidString: "11111111-1111-4111-8111-111111111102")!,
        UUID(uuidString: "22222222-2222-4222-8222-222222222201")!,
        UUID(uuidString: "22222222-2222-4222-8222-222222222202")!,
    ]

    func prepare(on database: Database) async throws {

        let pairs: [(UUID, String, String, String, String)] = [
            (
                seededIDs[0],
                "europe",
                "Marie Curie",
                "marie",
                "Physicist · explored radioactivity."
            ),
            (
                seededIDs[1],
                "europe",
                "Alan Turing",
                "alan",
                "Mathematician · computation & AI foundations."
            ),
            (
                seededIDs[2],
                "east-coast",
                "Grace Hopper",
                "grace",
                "Rear admiral · FLOW-MATIC & COBOL."
            ),
            (
                seededIDs[3],
                "east-coast",
                "Dennis Ritchie",
                "dmr",
                "Created C · Unix co-author."
            ),
        ]

        for row in pairs {
            let user = User(id: row.0, division: row.1, displayName: row.2, handle: row.3)
            try await user.save(on: database)

            let profile = Profile(id: row.0, bio: row.4, division: row.1)
            try await profile.save(on: database)
        }
    }

    func revert(on database: Database) async throws {
        for id in seededIDs {
            try await Profile.query(on: database).filter(\.$id == id).delete()
            try await User.query(on: database).filter(\.$id == id).delete()
        }
    }
}
