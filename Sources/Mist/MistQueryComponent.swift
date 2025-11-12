import Vapor
import Fluent

/// A component that represents the result of a query rather than
/// a single model instance. Query components use a static ID and
/// re-render whenever their query result changes.
public protocol QueryComponent: Component
{
    /// A static, hard-coded UUID used to identify this singleton
    /// component in the DOM and for websocket messages.
    /// This MUST match the `mist-id` in the Leaf template.
    var staticID: UUID { get }
    
    /// Executes this component's query and returns the model
    /// that should be rendered, or nil if nothing should be shown.
    func queryModel(on db: Database) async -> (any Model)?
}

public extension QueryComponent
{
    /// Query components typically want to update on any change
    /// to their watched models, since any change could affect
    /// which model the query returns.
    func shouldUpdate<M: Model>(for model: M) -> Bool
    {
        return models.contains { $0 == M.self }
    }
    
    /// Query components don't use the standard allModels approach
    /// for rendering multiple instances.
    func allModels(on db: Database) async -> [any Model]?
    {
        return nil
    }
}

