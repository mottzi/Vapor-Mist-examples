import Vapor
import Mist
import Elementary
import Fluent

// MARK: - 1. Page Template
struct LivePollingExamplePage: HTMLDocument {
    var title = "Live Polling Example"

    var head: some HTML {
        meta(.name(.description), .content("Live database aggregation with Mist PollingComponent"))
        link(.rel(.stylesheet), .href("/mistexamples.css"))
        style {
            """
            progress { width: 100%; height: 24px; accent-color: #3b82f6; }
            .accent-green { accent-color: #10b981; }
            .poll-grid { display: grid; gap: 1rem; }
            """
        }
    }

    var body: some HTML {
        main(.class("container")) {
            a(.href("/MistExamples"), .class("back-link")) { "← Back to Examples" }
            
            header(.class("mb-4")) {
                h1 { "Live Community Poll" }
                p(.class("desc")) { "Demonstrates a PollingComponent aggregating database records. Vote below and watch the progress bars update globally." }
            }
            
            div(.class("poll-grid")) {
                // The Unified Widget
                LiveVotingResultsComponent()
                    .body(context: LiveVotingResultsComponent.PollContext(tabs: 0, spaces: 0))
            }
        }
        
        script(.src("/morphdom.js")) {}
        script(.src("/mist.js")) {}
    }
}

// MARK: - 2. Database Model
final class VoteModel: Mist.Model, Content, @unchecked Sendable {
    
    static let schema = "PollVotes"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "choice") var choice: String
    
    init() {}
    init(choice: String) { self.choice = choice }
}

extension VoteModel {
    struct Table: AsyncMigration {
        func prepare(on database: Database) async throws {
            try await database.schema(VoteModel.schema)
                .id()
                .field("choice", .string, .required)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(VoteModel.schema).delete()
        }
    }
}

// MARK: - 3. The Unified Polling Component
struct LiveVotingResultsComponent: PollingComponent {
    
    struct PollContext: ComponentData {
        var tabs: Int
        var spaces: Int
        
        var total: Int { tabs + spaces }
        var tabsPercent: Double { total > 0 ? (Double(tabs) / Double(total)) * 100 : 50 }
        var spacesPercent: Double { total > 0 ? (Double(spaces) / Double(total)) * 100 : 50 }
    }
    
    let name = "live-voting-results"
    
    // Actions are now directly attached to the PollingComponent
    var actions: [any Action] { [VoteTabsAction(), VoteSpacesAction()] }
    
    // Polls the database every 2 seconds
    var refreshInterval: Duration { .seconds(2) }

    // Aggregates the votes from the Fluent Database
    func poll(on db: Database) async -> PollContext? {
        let tabsCount = (try? await VoteModel.query(on: db).filter(\.$choice == "tabs").count()) ?? 0
        let spacesCount = (try? await VoteModel.query(on: db).filter(\.$choice == "spaces").count()) ?? 0
        
        return PollContext(tabs: tabsCount, spaces: spacesCount)
    }

    // Renders Native HTML
    func body(context: PollContext) -> some HTML {
        div(
            .mistComponent(value: name),
            .class("card stack")
        ) {
            h2 { "Tabs vs. Spaces" }
            p(.class("desc mb-4")) { "Total Votes: \(context.total)" }
            
            // --- Progress Bars ---
            div(.class("stack")) {
                div {
                    div(.style("display: flex; justify-content: space-between; font-weight: bold;")) {
                        span { "Tabs" }
                        span { "\(Int(context.tabsPercent))%" }
                    }
                    div(.style("background: #e2e8f0; border-radius: 999px; height: 24px; overflow: hidden; margin-top: 4px;")) {
                        div(.style("background: #3b82f6; width: \(Int(context.tabsPercent))%; height: 100%; transition: width 0.3s;")) {}
                    }
                }
                
                div {
                    div(.style("display: flex; justify-content: space-between; font-weight: bold;")) {
                        span { "Spaces" }
                        span { "\(Int(context.spacesPercent))%" }
                    }
                    div(.style("background: #e2e8f0; border-radius: 999px; height: 24px; overflow: hidden; margin-top: 4px;")) {
                        div(.style("background: #10b981; width: \(Int(context.spacesPercent))%; height: 100%; transition: width 0.3s;")) {}
                    }
                }
            }
            
            // --- Voting Buttons ---
            div(.style("display: flex; gap: 1rem; margin-top: 1.5rem;")) {
                button(.mistAction(value: "vote-tabs"), .class("btn-large"), .style("width: 100%;")) {
                    "Vote Tabs"
                }
                button(.mistAction(value: "vote-spaces"), .class("btn-large"), .style("width: 100%; background-color: #10b981;")) {
                    "Vote Spaces"
                }
            }
        }
    }
}

// MARK: - 4. Actions
struct VoteTabsAction: Action {
    let name = "vote-tabs"
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        try? await VoteModel(choice: "tabs").save(on: app.db)
        return .success()
    }
}

struct VoteSpacesAction: Action {
    let name = "vote-spaces"
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        try? await VoteModel(choice: "spaces").save(on: app.db)
        return .success()
    }
}
