import Vapor
import Fluent

public protocol InstanceComponent: Component
{
    func allModels(on db: Database) async -> [any Model]?
}

public extension InstanceComponent
{
    func allModels(on db: Database) async -> [any Model]?
    {
        guard let primaryModelType = models.first else { return nil }
        return await primaryModelType.findAll(on: db)
    }
    
    func makeContext(of componentID: UUID, in db: Database) async -> SingleComponentContext?
    {
        var container = ModelContainer()
        
        for model in models 
        {
            guard let modelData = await model.find(id: componentID, on: db) else { continue }
            let modelName = String(describing: model).lowercased()
            container.add(modelData, for: modelName)
        }
        
        // [NEW] Inject ClientInteractive data if present
        if let interactive = self as? ClientInteractive 
        {
            // Encode state to JSON String for HTML attribute
            // Leaf will automatically escape this for HTML attributes
            if let stateData = try? JSONEncoder().encode(AnyEncodable(interactive.clientState)),
               let stateString = String(data: stateData, encoding: .utf8) {
                container.addMeta(stateString, for: "_mistState")
            }
            
            // Encode logic to JSON String for HTML attribute
            // Leaf will automatically escape this for HTML attributes
            if let logicData = try? JSONEncoder().encode(AnyEncodable(interactive.clientLogic)),
               let logicString = String(data: logicData, encoding: .utf8) {
                container.addMeta(logicString, for: "_mistLogic")
            }
        }
        
        guard container.hasElements else { return nil }
        
        return SingleComponentContext(component: container)
    }
}

public extension InstanceComponent
{
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

public extension InstanceComponent
{
    func handleCreate(id: UUID, app: Application) async
    {
        guard let html = await render(id: id, on: app.db, using: app.leaf.renderer) else { return }
        await app.mist.clients.broadcast(Message.InstanceCreate(component: name, id: id, html: html))
    }

    func handleUpdate(id: UUID, app: Application) async
    {
        guard let html = await render(id: id, on: app.db, using: app.leaf.renderer) else { return }
        await app.mist.clients.broadcast(Message.InstanceUpdate(component: name, id: id, html: html))
    }

    func handleDelete(id: UUID, app: Application) async
    {
        await app.mist.clients.broadcast(Message.InstanceDelete(component: name, id: id))
    }
}

