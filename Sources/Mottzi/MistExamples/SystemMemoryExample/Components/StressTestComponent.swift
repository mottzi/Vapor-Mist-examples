import Vapor
import Mist
import Elementary
import Foundation

struct StressTestComponent: ManualComponent {

    struct State: ComponentData {}

    let state = LiveState(of: State())

    var actions: [any Action] { [StressTestAction()] }

    func body(state: State) -> some HTML {
        div(
            .mistComponent(value: name),
            .class("stack"),
            .style("align-items: center; gap: 1rem;")
        ) {
            button(.mistAction(value: "stress-test"), .class("btn-danger")) {
                "Stress Test Server (5s)"
            }

            div(.style("padding: 0.5rem; background: var(--color-primary); border-radius: 8px; font-size: 0.85rem; color: var(--text-secondary); font-family: var(--font-mono);")) {
                "Refreshing every 2s"
            }
        }
    }
}

struct StressTestAction: Action {
    let name = "stress-test"

    func perform(targetID: UUID?, state: inout ComponentState, app: Application) async -> ActionResult {
        Task.detached(priority: .background) {
            let endTime = Date().addingTimeInterval(5)

            // Allocate memory to spike RAM (approx 200MB)
            let byteCount = 200 * 1024 * 1024
            let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: byteCount, alignment: 8)

            // Force OS to commit physical memory pages (write 1 byte per 4KB page)
            for i in stride(from: 0, to: byteCount, by: 4096) {
                buffer.storeBytes(of: 1, toByteOffset: i, as: UInt8.self)
            }

            // Busy loop to spike CPU
            while Date() < endTime {
                // spin
            }

            // Explicitly deallocate to immediately return memory to OS
            buffer.deallocate()
        }
        return .success()
    }
}
