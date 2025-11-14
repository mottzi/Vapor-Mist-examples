import Vapor
import Fluent

public protocol QueryComponent: Component
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

