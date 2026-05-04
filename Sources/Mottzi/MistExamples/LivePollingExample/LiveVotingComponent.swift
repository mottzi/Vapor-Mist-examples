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
            .mistComponent(name),
            .class("card stack")
        ) {
            div(.class("stack"), .style("gap: 0.5rem;")) {
                h2(.style("margin: 0;")) { "Language Poll" }
            }
            p(.class("desc mb-4"), .style("font-weight: 600; color: var(--text-primary);")) { "\(context.total) votes" }
            
            div(.class("stack")) {
                div(.style("display: flex; justify-content: space-between; font-weight: 500; font-size: 0.875rem; color: var(--text-secondary); margin-bottom: 0.5rem;")) {
                    span { "Swift: \(Int(context.swiftPercent))%" }
                    span { "Kotlin: \(Int(context.kotlinPercent))%" }
                }
                div(.style("display: flex; background: #e5e7eb; border-radius: 999px; height: 16px; overflow: hidden;")) {
                    div(.style("background: #F05138; width: \(context.swiftPercent)%; height: 100%; transition: width 0.5s ease;")) {}
                    div(.style("background: #7F52FF; width: \(context.kotlinPercent)%; height: 100%; transition: width 0.5s ease;")) {}
                }
            }
            
            div(.style("display: flex; gap: 1rem; margin-top: 1.5rem;")) {
                button(.mistAction("vote-swift"), .class("btn-primary"), .style("flex: 1; background-color: #F05138; border-color: #F05138;")) {
                    "Vote Swift"
                }
                button(.mistAction("vote-kotlin"), .class("btn-primary"), .style("flex: 1; background-color: #7F52FF; border-color: #7F52FF;")) {
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
