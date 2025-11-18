import Vapor
import Fluent
import Leaf
import Mist

extension Application
{
    public struct Nova
    {
        public let app: Application
        // public var clients: MistClients { _clients }
    }
    
    public var nova: Nova { Nova(app: self) }
}

extension Application.Nova
{
    final class Storage: @unchecked Sendable
    {
        init() {}
        // var clients: Mist.Clients?
    }

    private struct Key: StorageKey { typealias Value = Storage }
    
    var _storage: Storage
    {
        if let existing = app.storage[Key.self] { return existing }
        let new = Storage()
        app.storage[Key.self] = new
        return new
    }
}   

// extension Application.Nova
// {
//     private struct ClientsKey: LockKey {}
//    
//     var _clients: Mist.Clients
//     {
//         return app.locks.lock(for: ClientsKey.self).withLock()
//         {
//             if let existing = _storage.clients { return existing }
//             let new = Mist.Clients(components: _components)
//             _storage.clients = new
//             return new
//         }
//     }
// }