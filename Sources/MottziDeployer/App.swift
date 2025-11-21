import Fluent
import FluentSQLiteDriver
import Mist
import Vapor

@main
struct DeployerApp {
    static func main() async throws {
        let env = try Environment.detect()
        let app = try await Application.make(env)

        // DISTINCT PORT: Run Deployer on 8081 (Mottzi runs on 8080)
        app.http.server.configuration.port = 8081

        // SHARED DATABASE
        // Both apps connect to the same file.
        app.databases.use(.sqlite(.file("deploy/Mottzi.db")), as: .sqlite)

        // Important: SQLite WAL mode allows concurrent reads/writes from two processes
        // You might need to run "PRAGMA journal_mode=WAL;" manually on the DB once.

        app.migrations.add(Deployment.Table())
        try await app.autoMigrate()  // Only Deployer should migrate Deployment table

        // Register Deployment Components
        await app.mist.use(DeploymentRow(), DeploymentStatus())

        app.views.use(.leaf)

        // Register Routes
        app.environment.useVariables()
        app.useWebhook()  // The GitHub listener
        app.useDeployPanel()  // The UI

        try await app.execute()
        try await app.asyncShutdown()
    }
}
