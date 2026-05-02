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
            h2 { "SWIFT VS. KOTLIN" }
            p(.class("desc mb-4")) { "Votes Cast: \(context.total)" }
            
            div(.class("stack")) {
                div {
                    div(.style("display: flex; justify-content: space-between; font-weight: bold;")) {
                        span { "Swift (Safety First)" }
                        span { "\(Int(context.swiftPercent))%" }
                    }
                    div(.style("background: #e2e8f0; border-radius: 999px; height: 24px; overflow: hidden; margin-top: 4px;")) {
                        div(.style("background: #F05138; width: \(Int(context.swiftPercent))%; height: 100%; transition: width 0.3s;")) {}
                    }
                }
                
                div {
                    div(.style("display: flex; justify-content: space-between; font-weight: bold;")) {
                        span { "Kotlin (Conciseness Matters)" }
                        span { "\(Int(context.kotlinPercent))%" }
                    }
                    div(.style("background: #e2e8f0; border-radius: 999px; height: 24px; overflow: hidden; margin-top: 4px;")) {
                        div(.style("background: #7F52FF; width: \(Int(context.kotlinPercent))%; height: 100%; transition: width 0.3s;")) {}
                    }
                }
            }
            
            div(.style("display: flex; gap: 1rem; margin-top: 1.5rem;")) {
                button(.mistAction(value: "vote-swift"), .class("btn-large"), .style("width: 100%; background-color: #F05138;")) {
                    "VOTE SWIFT"
                }
                button(.mistAction(value: "vote-kotlin"), .class("btn-large"), .style("width: 100%; background-color: #7F52FF;")) {
                    "VOTE KOTLIN"
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
