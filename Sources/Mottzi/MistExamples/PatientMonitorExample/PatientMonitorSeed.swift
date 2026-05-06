import Fluent
import Vapor
import Mist

struct PatientMonitorSeed: AsyncMigration {
    func prepare(on database: Database) async throws {
        let patients = [
            ("John Doe", "1985-05-15", "O+"),
            ("Jane Smith", "1992-11-22", "A-"),
            ("Robert Brown", "1978-02-03", "B+")
        ]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for (name, dobString, bloodType) in patients {
            let id = UUID()
            let dob = formatter.date(from: dobString) ?? Date()
            
            let patient = Patient(id: id, name: name, dob: dob, bloodType: bloodType)
            try await patient.save(on: database)
            
            let vitals = Vitals(id: id, heartRate: 72, oxygenLevel: 98, statusColor: "green")
            try await vitals.save(on: database)
        }
    }

    func revert(on database: Database) async throws {
        try await Vitals.query(on: database).delete()
        try await Patient.query(on: database).delete()
    }
}
