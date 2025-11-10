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
        let lock = self.application.locks.lock(for: ClientsKey.self)
        return lock.withLock
        {
            if let existing = _storage.clients { return existing }
            let new = Mist.Clients(components: _components)
            _storage.clients = new
            return new
        }
    }
    
    var _components: Mist.Components
    {
        let lock = self.application.locks.lock(for: ComponentsKey.self)
        return lock.withLock
        {
            if let existing = _storage.components { return existing }
            let new = Mist.Components()
            _storage.components = new
            return new
        }
    }
}

extension Application.Leaf 
{    
    var defaultSource: NIOLeafFiles 
    {
        return NIOLeafFiles(
            fileio: self.application.fileio,
            limits: .default,
            sandboxDirectory: self.configuration.rootDirectory,
            viewDirectory: self.configuration.rootDirectory
        )
    }
    
}
