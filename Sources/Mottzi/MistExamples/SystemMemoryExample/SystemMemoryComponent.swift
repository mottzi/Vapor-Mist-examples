import Vapor
import Mist
import Elementary

struct SystemMemoryComponent: LiveComponent {

    struct SystemMetrics: ComponentData {
        var memoryUsage: Int
    }
    
    let state = LiveState(of: SystemMetrics(memoryUsage: getSystemMemoryUsageMB()))
    
    var refreshInterval: Duration { .seconds(2) }

    func refresh(app: Application) async {
        let realUsageMB = getSystemMemoryUsageMB()
        await state.set(.init(memoryUsage: realUsageMB))
    }

    func body(state: SystemMetrics) -> some HTML {
        div(
            .mistComponent(value: name),
            .class("card stack text-center mx-auto max-w-sm")
        ) {
            div(.class("stack"), .style("gap: 0.5rem; align-items: center;")) {
                span(.class("badge")) { "LiveComponent" }
                h2(.style("margin: 0;")) { "Memory Usage" }
            }
            div(.class("stack")) {
                div(.class("text-huge")) {
                    "\(state.memoryUsage) MB"
                }
            }
            
            div(.style("margin-top: 1rem; padding: 0.5rem; background: var(--color-primary); border-radius: 8px; font-size: 0.85rem; color: var(--text-secondary); font-family: var(--font-mono);")) {
                "Refreshing every 2s"
            }
        }
    }
    
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