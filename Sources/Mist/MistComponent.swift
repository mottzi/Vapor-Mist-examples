import Vapor
import Fluent

public protocol InstanceComponent: Sendable
{
    var name: String { get }
    var template: Template { get }
    var models: [any Model.Type] { get }
    var actions: [any Action] { get }

    func shouldUpdate<M: Model>(for model: M) -> Bool
    func allModels(on db: Database) async -> [any Model]?
}

public extension InstanceComponent
{
    var name: String { String(describing: Self.self) }
    var template: Template { .file(path: name) }
    var actions: [any Action] { [] }
}

public extension InstanceComponent
{    
    func shouldUpdate<M: Model>(for model: M) -> Bool 
    {
        return models.contains { $0 == M.self }
    }

    func allModels(on db: Database) async -> [any Model]?
    {
        guard let primaryModelType = models.first else { return nil }
        return await primaryModelType.findAll(on: db)
    }
}

public extension InstanceComponent
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

public extension InstanceComponent
{
    func makeContext(of componentID: UUID, in db: Database) async -> SingleComponentContext?
    {
        var container = ModelContainer()
        
        for model in models {
            guard let modelData = await model.find(id: componentID, on: db) else { continue }
            let modelName = String(describing: model).lowercased()
            container.add(modelData, for: modelName)
        }
        
        guard container.hasElements else { return nil }
        
        return SingleComponentContext(component: container)
    }
    
    func makeContext(ofAll db: Database) async -> MultipleComponentContext
    {
        var modelContainers: [ModelContainer] = []

        guard let primaryModels = await allModels(on: db) else { return .empty }

        for primaryModel in primaryModels
        {
            guard let modelID = primaryModel.id else { continue }
            guard let modelContext = await makeContext(of: modelID, in: db) else { continue }

            modelContainers.append(modelContext.component)
        }

        guard modelContainers.isEmpty == false else { return .empty }

        return MultipleComponentContext(components: modelContainers)
    }
    
}

public enum Template: Sendable
{
    case file(path: String)
    case inline(template: String)
}

public protocol QueryComponent: InstanceComponent
{    
    func queryModel(on db: Database) async -> (any Model)?
}

public extension QueryComponent
{
    func shouldUpdate<M: Model>(for model: M) -> Bool
    {
        return models.contains { $0 == M.self }
    }
    
    func allModels(on db: Database) async -> [any Model]?
    {
        return nil
    }
}