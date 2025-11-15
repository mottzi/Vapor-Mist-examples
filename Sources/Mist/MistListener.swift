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
        await handle(event: .create, model: model, db: db)
    }

    func update(model: M, on db: Database, next: AnyAsyncModelResponder) async throws
    {
        try await next.update(model, on: db)
        await handle(event: .update, model: model, db: db)
    }

    func delete(model: M, force: Bool, on db: any Database, next: any AnyAsyncModelResponder) async throws
    {
        try await next.delete(model, force: force, on: db)
        await handle(event: .delete, model: model, db: db)
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
                await queryComponent.handleQueryUpdate(app: app)
            }
            else
            {
                guard let modelID = model.id else { continue }

                switch event
                {
                    case .create: await component.handleCreate(id: modelID, app: app)
                    case .update: await component.handleUpdate(id: modelID, app: app)
                    case .delete: await component.handleDelete(id: modelID, app: app)
                }
            }
        }
    }
}
