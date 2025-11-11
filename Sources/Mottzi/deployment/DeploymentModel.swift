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
    
    static var findAll: (Database) async -> [any Mist.Model]?
    {
        return { db in
            guard let deployments = try? await Deployment.query(on: db)
                .sort(\.$startedAt, .descending)
                .all()
            else { return nil }
            return deployments
        }
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
        "startedAtTimestamp": startedAtTimestamp,
        "displayStatus": displayStatus
    ]}
    
    var durationString: String? {
        guard let finishedAt, let startedAt else { return nil }
        return String(format: "%.1fs", finishedAt.timeIntervalSince(startedAt))
    }
    
    var startedAtTimestamp: Double? { startedAt?.timeIntervalSince1970 }
    
    var displayStatus: String {
        // If status is "running" but it's been more than 30 minutes, it's "stale"
        if status == "running",
           let startedAt = startedAt,
           Date.now.timeIntervalSince(startedAt) > 1800 {
            return "stale"
        }
        
        // Otherwise, return the actual status from the database
        return status
    }
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
            deployment.status = "success"
            try await deployment.save(on: database)
        }
        
        self.isCurrent = true
        self.status = "deployed"
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


