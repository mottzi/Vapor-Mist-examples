import Vapor
import Fluent

public protocol Component: Sendable
{
    var name: String { get }
    var template: Template { get }
    var models: [any Model.Type] { get }
    var actions: [any Action] { get }

    func shouldUpdate<M: Model>(for model: M) -> Bool
}

public extension Component
{
    var name: String { String(describing: Self.self) }
    var template: Template { .file(path: name) }
    var actions: [any Action] { [] }
}

public extension Component // overridable
{
    func shouldUpdate<M: Model>(for model: M) -> Bool 
    {
        return models.contains { $0 == M.self }
    }
}

public enum Template: Sendable
{
    case file(path: String)
    case inline(template: String)
}

public extension Component // not-overridable
{
    func render(id: UUID, on db: Database, using renderer: ViewRenderer) async -> String?
    {
        guard let context = await makeContext(of: id, in: db) else { return nil }
        let templateName = switch template {
            case .file(let path): path
            case .inline: name
        }
        guard let buffer = try? await renderer.render(templateName, context).data else { return nil }
        return String(buffer: buffer)
    }
}

public extension Component // not-overridable
{
    func makeContext(of componentID: UUID, in db: Database) async -> SingleComponentContext?
    {
        var container = ModelContainer()
        
        for model in models 
        {
            guard let modelData = await model.find(id: componentID, on: db) else { continue }
            let modelName = String(describing: model).lowercased()
            container.add(modelData, for: modelName)
        }
        
        guard container.hasElements else { return nil }
        
        return SingleComponentContext(component: container)
    }
}

