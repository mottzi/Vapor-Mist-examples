import Vapor
import Fluent

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

public extension QueryComponent
{
    func handleQueryUpdate(app: Application) async
    {
        if let model = await queryModel(on: app.db),
           let modelID = model.id,
           let html = await render(id: modelID, on: app.db, using: app.leaf.renderer)
        {
            await app.mist.clients.broadcast(Message.QueryUpdate(component: name, html: html))
        }
        else
        {
            await app.mist.clients.broadcast(Message.QueryDelete(component: name))
        }
    }
}

