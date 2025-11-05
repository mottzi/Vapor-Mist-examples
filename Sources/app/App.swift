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
        
        app.databases.use(.sqlite(.file("deploy/github/deployments.db")), as: .sqlite)
        app.databases.middleware.use(Deployment.Listener(), on: .sqlite)
        app.migrations.add([
            Deployment.Table(),
            DemoModel1.Table(),
            DemoModel2.Table()
        ])
        try await app.autoMigrate()
        
        await Mist.configure(using:
            Mist.Configuration(
                for: app,
                components: [
                    DemoComponentRed(),
                    DemoComponentGreen(),
                    DemoComponentBlue(),
                ]
            )
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
