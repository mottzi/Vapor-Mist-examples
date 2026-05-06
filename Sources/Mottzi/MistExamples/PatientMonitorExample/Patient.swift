import Vapor
import Fluent
import Mist

final class Patient: Mist.Model, Content, @unchecked Sendable {
    static let schema = "medical_patients"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "dob")
    var dob: Date

    @Field(key: "blood_type")
    var bloodType: String

    init() {}

    init(id: UUID? = nil, name: String, dob: Date, bloodType: String) {
        self.id = id
        self.name = name
        self.dob = dob
        self.bloodType = bloodType
    }
}

extension Patient {
    struct Migration: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(Patient.schema)
                .id()
                .field("name", .string, .required)
                .field("dob", .datetime, .required)
                .field("blood_type", .string, .required)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Patient.schema).delete()
        }
    }
}
