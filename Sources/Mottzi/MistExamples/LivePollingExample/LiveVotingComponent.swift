import Vapor
import Fluent
import Mist
import Elementary

struct LiveVotingComponent: PollingComponent {
    
    let name = "live-voting-results"
    
    var actions: [any Action] { [VoteSwiftAction(), VoteKotlinAction()] }
    
    var refreshInterval: Duration { .seconds(2) }

    func poll(on db: Database) async -> LiveVotingContext? {
        
        let swiftCount = (try? await LiveVotingModel.query(on: db).filter(\.$choice == "swift").count()) ?? 0
        let kotlinCount = (try? await LiveVotingModel.query(on: db).filter(\.$choice == "kotlin").count()) ?? 0
        return LiveVotingContext(swift: swiftCount, kotlin: kotlinCount)
    }

    func body(context: LiveVotingContext) -> some HTML {
        div(
            .mistComponent(value: name),
            .class("card stack")
        ) {
            header(.class("stack gap-2")) {
                h2(.class("m-0")) { "Language Poll" }
            }
            p(.class("poll-vote-count")) { "\(context.total) votes" }

            div(.class("poll-results")) {
                div(.class("poll-info")) {
                    span { "Swift: \(Int(context.swiftPercent))%" }
                    span { "Kotlin: \(Int(context.kotlinPercent))%" }
                }
                div(.class("poll-bar-container")) {
                    div(.class("poll-bar-swift"), .style("width: \(context.swiftPercent)%;")) {}
                    div(.class("poll-bar-kotlin"), .style("width: \(context.kotlinPercent)%;")) {}
                }
            }

            div(.class("poll-actions")) {
                button(.mistAction(value: "vote-swift"), .class("btn-primary poll-btn-swift")) {
                    "Vote Swift"
                }
                button(.mistAction(value: "vote-kotlin"), .class("btn-primary poll-btn-kotlin")) {
                    "Vote Kotlin"
                }
            }
        }
    }
}

struct VoteSwiftAction: Action {
    
    let name = "vote-swift"
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        try? await LiveVotingModel(choice: "swift").save(on: app.db)
        return .success()
    }
    
}

struct VoteKotlinAction: Action {
    
    let name = "vote-kotlin"
    
    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        try? await LiveVotingModel(choice: "kotlin").save(on: app.db)
        return .success()
    }
    
}

struct LiveVotingContext: ComponentData {
    
    var swift: Int
    var kotlin: Int
    
    var total: Int { swift + kotlin }
    var swiftPercent: Double { total > 0 ? (Double(swift) / Double(total)) * 100 : 50 }
    var kotlinPercent: Double { total > 0 ? (Double(kotlin) / Double(total)) * 100 : 50 }
    
}