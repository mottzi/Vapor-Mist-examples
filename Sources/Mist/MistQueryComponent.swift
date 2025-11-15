import Vapor
import Fluent

public protocol QueryComponent: Component
{
    func queryModel(on db: Database) async -> (any Model)?
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

