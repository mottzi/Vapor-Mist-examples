import Vapor
import Fluent
import FluentSQLiteDriver
import Mist

@main struct MottziApp {

    static func main() async throws {
        let env = try Environment.detect()
        let app = try await Application.make(env)

        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

        app.databases.use(.sqlite(.file("deploy/mottzi.db")), as: .sqlite)
//        app.migrations.add(
//            MistDemoModel1.Table(),
//            MistDemoModel2.Table()
//        )
        try await app.autoMigrate()

        try await app.mist.use {
//                        MistDemoComponent()
            //            MistDemoHeader()
            CounterComponent()
        }

        app.views.use(.leaf)

        app.useMistDemo()

        try await app.execute()
        try await app.asyncShutdown()
    }

}
