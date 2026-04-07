import Fluent
import FluentSQLiteDriver
import Leaf
import Mist
import Vapor

@main
struct MottziApp {
    static func main() async throws {
        let env = try Environment.detect()
        let app = try await Application.make(env)

        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

        app.databases.use(.sqlite(.file("deploy/mottzi.db")), as: .sqlite)
        app.migrations.add(
            MistDemoModel1.Table(),
            MistDemoModel2.Table()
        )
        try await app.autoMigrate()

        await app.mist.use(
            MistDemoComponent(),
            MistDemoHeader()
        )

        app.views.use(.leaf)

        app.useMistDemo()

        try await app.execute()
        try await app.asyncShutdown()
    }
}

// 2
