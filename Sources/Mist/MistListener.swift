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
        await self.handle(event: .create, model: model, db: db)
    }

    func update(model: M, on db: Database, next: AnyAsyncModelResponder) async throws
    {
        try await next.update(model, on: db)
        await self.handle(event: .update, model: model, db: db)
    }

    func delete(model: M, force: Bool, on db: any Database, next: any AnyAsyncModelResponder) async throws
    {
        try await next.delete(model, force: force, on: db)
        await self.handle(event: .delete, model: model, db: db)
    }
}

extension Listener
{
    enum ModelEvent
    {
        case create
        case update
        case delete
    }
    
    func handle(event: ModelEvent, model: M, db: Database) async
    {
        for component in await app.mist.components.getComponents(using: M.self)
        {
            guard component.shouldUpdate(for: model) else { continue }

            if let queryComponent = component as? QueryComponent
            {
                await self.handleQueryComponent(component: queryComponent, on: db)
            }
            else
            {
                guard let modelID = model.id else { continue }

                switch event
                {
                    case .create: await self.handleInstanceCreate(id: modelID, component: component, on: db)
                    case .update: await self.handleInstanceUpdate(id: modelID, component: component, on: db)
                    case .delete: await self.handleInstanceDelete(id: modelID, component: component)
                }
            }
        }
    }
}

extension Listener
{
    func handleInstanceCreate(id: M.IDValue, component: any InstanceComponent, on db: Database) async
    {
        guard let html = await component.render(id: id, on: db, using: app.leaf.renderer) else { return }
        await app.mist.clients.broadcast(Message.InstanceCreate(component: component.name, id: id, html: html))
    }

    func handleInstanceUpdate(id: M.IDValue, component: any InstanceComponent, on db: Database) async
    {
        guard let html = await component.render(id: id, on: db, using: app.leaf.renderer) else { return }
        await app.mist.clients.broadcast(Message.InstanceUpdate(component: component.name, id: id, html: html))
    }

    func handleInstanceDelete(id: M.IDValue, component: any InstanceComponent) async
    {
        await app.mist.clients.broadcast(Message.InstanceDelete(component: component.name, id: id))
    }
}

extension Listener
{
    func handleQueryComponent(component: QueryComponent, on db: Database) async
    {
        if let model = await component.queryModel(on: db),
           let modelID = model.id,
           let html = await component.render(id: modelID, on: db, using: app.leaf.renderer)
        {
            await app.mist.clients.broadcast(Message.QueryUpdate(component: component.name, html: html))
        }
        else
        {
            await app.mist.clients.broadcast(Message.QueryDelete(component: component.name))
        }
    }
}
