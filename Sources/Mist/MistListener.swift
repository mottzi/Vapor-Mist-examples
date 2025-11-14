import Vapor
import Fluent

extension Mist.Model
{
    static func registerListener(with app: Application)
    {
        let listener = Listener<Self>(app: app)
        app.databases.middleware.use(listener)
    }
}

struct Listener<M: Model>: AsyncModelMiddleware
{
    let app: Application

    func create(model: M, on db: Database, next: AnyAsyncModelResponder) async throws
    {
        try await next.create(model, on: db)

        guard let modelID = model.id else { return }
        
        for component in await app.mist.components.getComponents(using: M.self)
        {
            guard component.shouldUpdate(for: model) else { continue }
            
            if let queryComponent = component as? QueryComponent
            {
                // Query-based component: re-run query and render result
                guard let queriedModel = await queryComponent.queryModel(on: db),
                      let queriedID = queriedModel.id
                else {
                    // No result - broadcast delete to hide the component
                    await app.mist.clients.broadcast(
                        Message.QueryDelete(
                            component: queryComponent.name
                        )
                    )
                    continue
                }
                
                // Render using the queried model's ID
                guard let html = await queryComponent.render(
                    id: queriedID,
                    on: db,
                    using: app.leaf.renderer
                ) else { continue }
                
                // Broadcast update (query components are singleton-like)
                await app.mist.clients.broadcast(
                    Message.QueryUpdate(
                        component: queryComponent.name,
                        html: html
                    )
                )
            }
            else
            {
                // Regular instance component
                guard let html = await component.render(
                    id: modelID,
                    on: db,
                    using: app.leaf.renderer)
                else { continue }
                
                await app.mist.clients.broadcast(
                    Message.InstanceCreate(
                        component: component.name,
                        id: modelID,
                        html: html
                    )
                )
            }
        }
    }
    
    func update(model: M, on db: Database, next: AnyAsyncModelResponder) async throws
    {
        try await next.update(model, on: db)

        guard let modelID = model.id else { return }
        
        for component in await app.mist.components.getComponents(using: M.self)
        {
            guard component.shouldUpdate(for: model) else { continue }
            
            if let queryComponent = component as? QueryComponent
            {
                // Query-based component: re-run query and render result
                guard let queriedModel = await queryComponent.queryModel(on: db),
                      let queriedID = queriedModel.id
                else {
                    // No result - broadcast delete to hide the component
                    await app.mist.clients.broadcast(
                        Message.QueryDelete(
                            component: queryComponent.name
                        )
                    )
                    continue
                }
                
                // Render using the queried model's ID
                guard let html = await queryComponent.render(
                    id: queriedID,
                    on: db,
                    using: app.leaf.renderer
                ) else { continue }
                
                // Broadcast update (query components are singleton-like)
                await app.mist.clients.broadcast(
                    Message.QueryUpdate(
                        component: queryComponent.name,
                        html: html
                    )
                )
            }
            else
            {
                // Regular instance component
                guard let html = await component.render(
                    id: modelID,
                    on: db,
                    using: app.leaf.renderer)
                else { continue }
                
                await app.mist.clients.broadcast(
                    Message.InstanceUpdate(
                        component: component.name,
                        id: modelID,
                        html: html
                    )
                )
            }
        }
    }
    
    func delete(model: M, force: Bool, on db: any Database, next: any AnyAsyncModelResponder) async throws
    {
        try await next.delete(model, force: force, on: db)
        
        guard let modelID = model.id else { return }
        
        for component in await app.mist.components.getComponents(using: M.self)
        {
            guard component.shouldUpdate(for: model) else { continue }
            
            if let queryComponent = component as? QueryComponent
            {
                // Query-based component: re-run query after deletion
                guard let queriedModel = await queryComponent.queryModel(on: db),
                      let queriedID = queriedModel.id
                else {
                    // No result after deletion - hide the component
                    await app.mist.clients.broadcast(
                        Message.QueryDelete(
                            component: queryComponent.name
                        )
                    )
                    continue
                }
                
                // Another model now satisfies the query - update to show it
                guard let html = await queryComponent.render(
                    id: queriedID,
                    on: db,
                    using: app.leaf.renderer
                ) else { continue }
                
                // Broadcast update (query components are singleton-like)
                await app.mist.clients.broadcast(
                    Message.QueryUpdate(
                        component: queryComponent.name,
                        html: html
                    )
                )
            }
            else
            {
                // Regular instance component - delete the specific instance
                await app.mist.clients.broadcast(
                    Message.InstanceDelete(
                        component: component.name,
                        id: modelID
                    )
                )
            }
        }
    }
    
}
