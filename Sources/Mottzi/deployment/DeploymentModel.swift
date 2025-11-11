import Vapor
import Fluent
import Mist

final class Deployment: Mist.Model, Content, @unchecked Sendable
{
    static let schema = "deployments"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "status") var status: String
    @Field(key: "message") var message: String
    @Field(key: "is_current") var isCurrent: Bool
    @Timestamp(key: "started_at", on: .create) var startedAt: Date?
    @Timestamp(key: "finished_at", on: .none) var finishedAt: Date?
    
    init() {}
    
    init(status: String, message: String)
    {
        self.status = status
        self.message = message
        self.isCurrent = false
    }
    
    static func all(on database: Database) async throws -> [Deployment]
    {
        try await Deployment.query(on: database)
            .sort(\.$startedAt, .descending)
            .all()
            .markStales()
            .markCurrents()
    }
}

extension Deployment
{
    struct Table: AsyncMigration
    {
        func prepare(on database: Database) async throws
        {
            try await database.schema(Deployment.schema)
                .id()
                .field("status", .string, .required)
                .field("message", .string, .required)
                .field("is_current", .bool, .required, .sql(.default(false)))
                .field("started_at", .datetime)
                .field("finished_at", .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws
        {
            try await database.schema(Deployment.schema).delete()
        }
    }
}

extension Deployment
{
    func contextExtras() -> [String: any Encodable] {[
        "durationString": durationString,
        "startedAtTimestamp": startedAtTimestamp
    ]}
    
    var durationString: String? {
        guard let finishedAt, let startedAt else { return nil }
        return String(format: "%.1fs", finishedAt.timeIntervalSince(startedAt))
    }
    
    var startedAtTimestamp: Double? { startedAt?.timeIntervalSince1970 }
}

extension Deployment
{
    func setCurrent(on database: Database) async throws
    {
        let currentDeployments = try await Deployment.query(on: database)
            .filter(\.$isCurrent, .equal, true)
            .all()
        
        for deployment in currentDeployments {
            deployment.isCurrent = false
            try await deployment.save(on: database)
        }
        
        self.isCurrent = true
        try await self.save(on: database)
    }
    
    static func getCurrent(on database: Database) async throws -> Deployment?
    {
        try await Deployment.query(on: database)
            .filter(\.$isCurrent, .equal, true)
            .first()
    }
    
    static func clearCurrent(on database: Database) async throws
    {
        try await Deployment.query(on: database)
            .set(\.$isCurrent, to: false)
            .filter(\.$isCurrent, .equal, true)
            .update()
    }
}

extension Deployment
{
    @discardableResult
    func checkStale() -> Deployment
    {
        guard self.status == "running" else { return self }
        guard let startedAt = self.startedAt else { return self }
        guard Date.now.timeIntervalSince(startedAt) > 1800 else { return self }
        
        self.status = "stale"
        return self
    }
    
    @discardableResult
    func checkCurrent() -> Deployment
    {
        guard self.isCurrent else { return self }
        
        self.status = "deployed"
        return self
    }
}

extension Array where Element == Deployment
{
    func markStales() -> [Deployment] { self.map { $0.checkStale() } }
    func markCurrents() -> [Deployment] { self.map { $0.checkCurrent() } }
}

