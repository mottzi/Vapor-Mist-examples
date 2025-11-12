import Vapor
import Leaf
import Fluent
import FluentSQLiteDriver
import Mist

@main
struct App
{
    static func main() async throws
    {
        let env = try Environment.detect()
        let app = try await Application.make(env)
        
        app.environment.useVariables()
        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
        
        app.databases.use(.sqlite(.file("deploy/Mottzi.db")), as: .sqlite)
        app.migrations.add(
            Deployment.Table(),
            DemoModel1.Table(),
            DemoModel2.Table()
        )
        try await app.autoMigrate()
        
        await app.mist.use(
            DeploymentRow(),
            DeploymentStatusComponent(),
            MistDemoComponent()
        )
        
        app.views.use(.leaf)
        
        app.initMistDemo()
        app.initTestRoute()
        app.initPushWebhook()
        app.initDeployPanel()
        
        try await app.execute()
        try await app.asyncShutdown()
    }
}
