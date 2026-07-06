import Fluent
import FluentSQLiteDriver
import Mist
import ConsoleKit
import Vapor

@main struct App {
      
    static func main() async throws {
        var env = try Environment.detect()
        LoggingSystem.bootstrap(
            fragment: timestampDefaultLoggerFragment(),
            console: Terminal(),
            level: try Logger.Level.detect(from: &env)
        )
        let app = try await Application.make(env)
        
        fatalError("test exit!")
        
        try app.useVariables()

        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

        app.databases.use(.sqlite(.file("deploy/mottzi.db")), as: .sqlite)
        app.migrations.add(
            FlashcardFrontModel.Table(),
            FlashcardBackModel.Table(),
            LiveVotingModel.Table(),
            Patient.Migration(),
            Vitals.Migration(),
            PatientMonitorSeed()
        )
        try await app.autoMigrate()

        try await app.mist.use {
            FlashcardLeaf()
            FlashcardAddButtonLeaf()
            FlashcardElementary()
            FlashcardAddButtonElementary()
            CounterComponent()
            MemoryUsageComponent()
            CpuLoadComponent()
            ConnectedClientsComponent()
            StressTestComponent()
            LiveVotingComponent()
            PatientComponent()
        }

        app.views.use(.leaf)

        app.useMistExamples()
        app.registerTestRoute()

        PatientSimulator.start(app: app)

        try await app.execute()
        try await app.asyncShutdown()
    }

}
