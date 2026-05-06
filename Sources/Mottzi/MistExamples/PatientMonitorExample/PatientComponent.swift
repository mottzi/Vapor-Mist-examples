import Vapor
import Fluent
import Mist

struct PatientComponent: InstanceComponent {
    let name: String = "PatientComponent"
    let models: [any Mist.Model.Type] = [Patient.self, Vitals.self]
    let actions: [any Mist.Action] = [UpdateVitalsAction(), EmergencyAlertAction(), ResetVitalsAction()]
    let template: Mist.Template = LeafTemplate.file("PatientMonitorExample/PatientComponent")

    func allModels(on db: Database) async throws -> [any Mist.Model] {
        try await Patient.query(on: db).all().map { $0 as any Mist.Model }
    }
}

struct UpdateVitalsAction: Mist.Action {
    let name: String = "updateVitals"
    func perform(targetID id: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        guard let id, let vitals = try? await Vitals.find(id: id, on: app.db) as? Vitals else { return .failure("NotFound") }
        
        vitals.heartRate = Int.random(in: 65...85)
        vitals.oxygenLevel = Int.random(in: 95...100)
        vitals.statusColor = "green"
        
        try? await vitals.save(on: app.db)
        return .success()
    }
}

struct EmergencyAlertAction: Mist.Action {
    let name: String = "emergency"
    func perform(targetID id: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        guard let id, let vitals = try? await Vitals.find(id: id, on: app.db) as? Vitals else { return .failure("NotFound") }
        
        vitals.heartRate = Int.random(in: 120...160)
        vitals.oxygenLevel = Int.random(in: 80...90)
        vitals.statusColor = "red"
        
        try? await vitals.save(on: app.db)
        return .success()
    }
}

struct ResetVitalsAction: Mist.Action {
    let name: String = "reset"
    func perform(targetID id: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        guard let id, let vitals = try? await Vitals.find(id: id, on: app.db) as? Vitals else { return .failure("NotFound") }
        
        vitals.heartRate = 72
        vitals.oxygenLevel = 98
        vitals.statusColor = "green"
        
        try? await vitals.save(on: app.db)
        return .success()
    }
}
