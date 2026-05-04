import Vapor
import Mist
import Elementary
import Foundation

struct SystemMemoryComponent: LiveComponent {

    var actions: [any Action] { [StressTestAction()] }

    struct SystemMetrics: ComponentData {
        var memoryUsage: Int
        var cpuLoad: Double
    }
    
    let state = LiveState(of: SystemMetrics(memoryUsage: getSystemMemoryUsageMB(), cpuLoad: getSystemLoadAverage()))
    
    var refreshInterval: Duration { .seconds(2) }

    func refresh(app: Application) async {
        let realUsageMB = getSystemMemoryUsageMB()
        let realCpuLoad = getSystemLoadAverage()
        await state.set(.init(memoryUsage: realUsageMB, cpuLoad: realCpuLoad))
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
            var memoryHog = [String]()
            for i in 0..<5_000_000 {
                memoryHog.append("Stress Test String \(i)")
            }
            
            // Busy loop to spike CPU
            while Date() < endTime {
                // spin
            }
            
            // Prevent optimization from removing the memory hog
            let _ = memoryHog.count
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