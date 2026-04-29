import Fluent
import Mist
import Vapor

struct MistDemoComponent: Mist.InstanceComponent {
    let models: [any Mist.Model.Type] = [MistDemoModel1.self, MistDemoModel2.self]
    let actions: [any Mist.Action] = [DeleteAction(), RandomizeAction()]
    let template: Mist.Template = .file(path: "MistDemo/MistDemoComponent")
}

struct DeleteAction: Mist.Action {
    let name: String = "delete"

    func perform(id: UUID?, state: inout MistState, on db: Database) async -> ActionResult {
        guard let model1 = try? await MistDemoModel1.find(id, on: db) else {
            return .failure(message: "Model1 not found")
        }
        guard let model2 = try? await MistDemoModel2.find(id, on: db) else {
            return .failure(message: "Model2 not found")
        }
        guard (try? await model1.delete(on: db)) != nil else {
            return .failure(message: "Failed to delete Model1")
        }
        guard (try? await model2.delete(on: db)) != nil else {
            return .failure(message: "Failed to delete Model2")
        }

        return .success()
    }
}

struct RandomizeAction: Mist.Action {
    func perform(id: UUID?, state: inout MistState, on db: Database) async -> ActionResult {
        guard let model1 = try? await MistDemoModel1.find(id, on: db) else {
            return .failure(message: "Model1 not found")
        }
        guard let model2 = try? await MistDemoModel2.find(id, on: db) else {
            return .failure(message: "Model2 not found")
        }

        let words: Set<String> = [
            "Lorem", "Ipsum", "Dolor", "Sit", "Amet", "Consectetur", "Adipiscing", "Elit",
            "Sed", "Do", "Eiusmod", "Tempor", "Incididunt", "Ut", "Labore", "Et", "Dolore",
            "Magna", "Aliqua", "Enim", "Ad", "Minim", "Veniam", "Quis", "Nostrud",
            "Exercitation", "Ullamco", "Laboris", "Nisi", "Aliquip", "Ex", "Sunt",
            "Culpa", "Officia", "Deserunt", "Mollit", "Anim", "Id", "Est", "Laborum",
        ]

        model1.text = words.shuffled().prefix(2).joined(separator: " ")
        model2.text = words.shuffled().prefix(2).joined(separator: " ")

        guard (try? await model1.save(on: db)) != nil else {
            return .failure(message: "Failed to save Model1")
        }

        guard (try? await model2.save(on: db)) != nil else {
            return .failure(message: "Failed to save Model2")
        }

        return .success()
    }
}
