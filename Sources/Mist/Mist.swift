import Vapor
import Fluent
import Leaf
import LeafKit

extension Application
{
    public struct Mist
    {
        public let application: Application   
        public var clients: MistClients { _clients }
        public var components: Components { _components }
    }
    
    public var mist: Mist { Mist(application: self) }
}

extension Application.Mist
{
    public func use(_ components: [any InstanceComponent]) async {
        await configure(components: components, on: application)
    }
    
    public func use(_ components: any InstanceComponent...) async {
        await configure(components: components, on: application)
    }
}

extension Application.Mist
{
    final class Storage: @unchecked Sendable
    {
        init() {}
        var clients: Mist.Clients?
        var components: Mist.Components?
    }

    private struct Key: StorageKey { typealias Value = Storage }
    
    var _storage: Storage
    {
        if let existing = application.storage[Key.self] { return existing }
        let new = Storage()
        application.storage[Key.self] = new
        return new
    }
}

extension Application.Mist
{
    private struct ClientsKey: LockKey {}
    private struct ComponentsKey: LockKey {}
    
    var _clients: Mist.Clients
    {
        return application.locks.lock(for: ClientsKey.self).withLock {
            if let existing = _storage.clients { return existing }
            let new = Mist.Clients(components: _components)
            _storage.clients = new
            return new
        }
    }
    
    var _components: Mist.Components
    {
        return application.locks.lock(for: ComponentsKey.self).withLock {
            if let existing = _storage.components { return existing }
            let new = Mist.Components()
            _storage.components = new
            return new
        }
    }
}
