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
            .mistComponent(name),
            .class("stress-controls")
        ) {
            button(.mistAction("stress-test"), .class("btn-danger")) {
                "Run 5-second load test"
            }

            div(.class("refresh-note")) {
                "Metrics refresh every 2 seconds"
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
