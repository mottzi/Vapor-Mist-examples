import Vapor
import Fluent
import FluentSQLiteDriver
import Mist

@main struct App {

    static func main() async throws {
        let env = try Environment.detect()
        let app = try await Application.make(env)

        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

        app.databases.use(.sqlite(.file("deploy/mottzi.db")), as: .sqlite)
        app.migrations.add(
            FlashcardFrontModel.Table(),
            FlashcardBackModel.Table(),
            LiveVotingModel.Table()
        )
        try await app.autoMigrate()

        try await app.mist.use {
            FlashcardComponent()
            FlashcardCreateComponent()
            CounterComponent()
            SystemMemoryComponent()
            LiveVotingComponent()
        }

        app.views.use(.leaf)

        app.useMistExamples()

        try await app.execute()
        try await app.asyncShutdown()
    }

}
