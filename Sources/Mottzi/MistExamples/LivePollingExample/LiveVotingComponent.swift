import Elementary
import Fluent
import Mist
import Vapor

struct LiveVotingComponent: PollingComponent {

    var actions: [any Action] { [VoteSwiftAction(), VoteKotlinAction(), ResetPollAction()] }

    var refreshInterval: Duration { .seconds(1) }

    func poll(on db: Database) async -> LiveVotingContext? {

        let swiftCount = try? await LiveVotingModel.query(on: db).filter(\.$choice == "swift").count()
        let kotlinCount = try? await LiveVotingModel.query(on: db).filter(\.$choice == "kotlin").count()
        
        return LiveVotingContext(
            swift: swiftCount ?? 0,
            kotlin: kotlinCount ?? 0
        )
    }

    func body(context: LiveVotingContext) -> some HTML {
        div(
            .mistComponent(self.name),
            .class("card poll-card stack")
        ) {
            div(.class("poll-heading")) {
                div {
                    h2 { "Choose your language" }
                    p(.class("poll-count")) { "\(context.total) votes recorded" }
                }
                button(
                    .mistAction("reset-poll"),
                    .class("btn-quiet")
                ) { "Reset" }
            }

            div(.class("poll-result")) {
                div(.class("poll-labels")) {
                    span(.class("poll-label poll-label--swift")) {
                        i {}
                        strong { "Swift" }
                        em { "\(Int(context.swiftPercent))%" }
                    }
                    span(.class("poll-label poll-label--kotlin")) {
                        i {}
                        strong { "Kotlin" }
                        em { "\(Int(context.kotlinPercent))%" }
                    }
                }
                div(.class("poll-track")) {
                    div(
                        .class("poll-track__swift"),
                        .style(
                            "width: \(context.swiftPercent)%;"
                        )
                    ) {}
                    div(
                        .class("poll-track__kotlin"),
                        .style(
                            "width: \(context.kotlinPercent)%;"
                        )
                    ) {}
                }
            }

            div(.class("poll-actions")) {
                button(
                    .mistAction("vote-swift"), .class("vote-button vote-button--swift")
                ) {
                    span { "Vote for Swift" }
                    small { "Familiar, fast, native" }
                }
                button(
                    .mistAction("vote-kotlin"), .class("vote-button vote-button--kotlin")
                ) {
                    span { "Vote for Kotlin" }
                    small { "Concise, pragmatic, modern" }
                }
            }
        }
    }
}

struct VoteSwiftAction: Action {

    let name = "vote-swift"

    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async
        -> ActionResult
    {
        try? await LiveVotingModel(choice: "swift").save(on: app.db)
        return .success()
    }

}

struct VoteKotlinAction: Action {

    let name = "vote-kotlin"

    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async
        -> ActionResult
    {
        try? await LiveVotingModel(choice: "kotlin").save(on: app.db)
        return .success()
    }

}

struct ResetPollAction: Action {

    let name = "reset-poll"

    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async
        -> ActionResult
    {
        try? await LiveVotingModel.query(on: app.db).delete()
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
