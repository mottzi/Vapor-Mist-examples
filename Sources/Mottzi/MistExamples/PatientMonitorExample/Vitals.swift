import Vapor
import Fluent
import Mist

final class Vitals: Mist.Model, Content, @unchecked Sendable {
    static let schema = "medical_vitals"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "heart_rate")
    var heartRate: Int

    @Field(key: "oxygen_level")
    var oxygenLevel: Int

    @Field(key: "status_color")
    var statusColor: String // "green", "yellow", "red"

    init() {}

    init(id: UUID? = nil, heartRate: Int = 70, oxygenLevel: Int = 98, statusColor: String = "green") {
        self.id = id
        self.heartRate = heartRate
        self.oxygenLevel = oxygenLevel
        self.statusColor = statusColor
    }
}

extension Vitals {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Vitals.schema)
                .id()
                .field("heart_rate", .int, .required)
                .field("oxygen_level", .int, .required)
                .field("status_color", .string, .required)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Vitals.schema).delete()
        }
    }
}
