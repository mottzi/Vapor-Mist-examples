import Fluent
import FluentSQLiteDriver
import Mist
import Vapor

@main
struct DeployerApp {
    static func main() async throws {
        let env = try Environment.detect()
        let app = try await Application.make(env)
        app.http.server.configuration.port = 8081

        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

        app.databases.use(.sqlite(.file("deploy/Mottzi.db")), as: .sqlite)
        app.migrations.add(Deployment.Table())
        try await app.autoMigrate()  // Only Deployer should migrate Deployment table

        app.mist.socketPath = ["deployment", "ws"]
        await app.mist.use(DeploymentRow(), DeploymentStatus())

        app.views.use(.leaf)

        app.environment.useVariables()
        app.useWebhook()  // The GitHub listener
        app.useDeployPanel()  // The UI

        try await app.execute()
        try await app.asyncShutdown()
    }
}
