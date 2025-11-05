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
                
        app.initTestRoute()
        app.initPushWebhook()
        app.initDeployPanel()
        
        let components: [any Mist.Component] = [DemoComponent()]
        let config = Mist.Configuration(for: app, components: components)
        await Mist.configure(using: config)
        app.useMistDemo()
        
        app.views.use(.leaf)
                
        try await app.execute()
        try await app.asyncShutdown()
    }
}
