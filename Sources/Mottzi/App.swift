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
            LiveVotingModel.Table(),
            User.Table(),
            Profile.Table(),
            TeamProfileSeed(),
            Patient.Migration(),
            Vitals.Migration(),
            PatientMonitorSeed()
        )
        try await app.autoMigrate()

        try await app.mist.use {
            FlashcardComponent()
            FlashcardCreateComponent()
            CounterComponent()
            CounterComponent2()
            MemoryUsageComponent()
            CpuLoadComponent()
            ConnectedClientsComponent()
            StressTestComponent()
            LiveVotingComponent()
            for division in TeamProfileExample.divisions {
                ProfileComponent(division: division)
            }
            PatientComponent()
        }

        app.views.use(.leaf)

        app.useMistExamples()

        try await app.execute()
        try await app.asyncShutdown()
    }

}
