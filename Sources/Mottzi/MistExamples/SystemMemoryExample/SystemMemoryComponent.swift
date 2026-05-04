import Vapor
import Mist
import Elementary
import Foundation

struct SystemMemoryComponent: LiveComponent {

    var actions: [any Action] { [StressTestAction()] }

    struct SystemMetrics: ComponentData {
        var memoryUsage: Int
        var cpuLoad: Double
        var clientCount: Int
    }
    
    let state = LiveState(of: SystemMetrics(memoryUsage: getSystemMemoryUsageMB(), cpuLoad: getSystemLoadAverage(), clientCount: 0))
    
    var refreshInterval: Duration { .seconds(2) }

    func refresh(app: Application) async {
        let realUsageMB = getSystemMemoryUsageMB()
        let realCpuLoad = getSystemLoadAverage()
        let metrics = SystemMetrics(
            memoryUsage: realUsageMB,
            cpuLoad: realCpuLoad,
            clientCount: await app.mist.clients.count
        )
        await state.set(metrics)
    }

    func body(state: SystemMetrics) -> some HTML {
        div(
            .mistComponent(value: name),
            .class("stack"),
            .style("gap: 2rem; align-items: center;")
        ) {
            div(.class("inline"), .style("justify-content: center; gap: 2rem; flex-wrap: wrap;")) {
                // Memory Card
                div(.class("card stack text-center max-w-sm"), .style("flex: 1; min-width: 280px;")) {
                    div(.class("stack"), .style("gap: 0.5rem; align-items: center;")) {
                        h2(.style("margin: 0;")) { "Memory Usage" }
                    }
                    div(.class("text-huge")) {
                        "\(state.memoryUsage) MB"
                    }
                }
                
                // CPU Card
                div(.class("card stack text-center max-w-sm"), .style("flex: 1; min-width: 280px;")) {
                    div(.class("stack"), .style("gap: 0.5rem; align-items: center;")) {
                        h2(.style("margin: 0;")) { "System Load" }
                    }
                    div(.class("text-huge")) {
                        "\(String(format: "%.2f", state.cpuLoad))"
                    }
                }
                
                // Clients Card
                div(.class("card stack text-center max-w-sm"), .style("flex: 1; min-width: 280px;")) {
                    div(.class("stack"), .style("gap: 0.5rem; align-items: center;")) {
                        h2(.style("margin: 0;")) { "Connected Clients" }
                    }
                    div(.class("text-huge")) {
                        "\(state.clientCount)"
                    }
                }
            }
            
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

private func getSystemLoadAverage() -> Double {
    guard let loadavg = try? String(contentsOfFile: "/proc/loadavg", encoding: .utf8) else {
        return 0.0
    }
    
    let parts = loadavg.split(separator: " ", omittingEmptySubsequences: true)
    if parts.count >= 1, let load = Double(parts[0]) {
        return load
    }
    
    return 0.0
}

private func getSystemMemoryUsageMB() -> Int {

    guard let meminfo = try? String(contentsOfFile: "/proc/meminfo", encoding: .utf8) else {
        return 0
    }

    var memTotal: Double = 0
    var memAvailable: Double = 0

    let lines = meminfo.split(separator: "\n")
    for line in lines {
        if line.hasPrefix("MemTotal:") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            if parts.count >= 2, let kb = Double(parts[1]) {
                memTotal = kb
            }
        } else if line.hasPrefix("MemAvailable:") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            if parts.count >= 2, let kb = Double(parts[1]) {
                memAvailable = kb
            }
        }
    }

    if memTotal > 0 {
        let usedKB = memTotal - memAvailable
        return Int(usedKB / 1024.0) // Convert to MB
    }
    
    return 0
}
