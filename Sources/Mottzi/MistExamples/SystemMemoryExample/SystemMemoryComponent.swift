import Vapor
import Mist
import Elementary

struct SystemMemoryComponent: LiveComponent {

    struct SystemMetrics: ComponentData {
        var memoryUsage: Double
    }
    
    let state = LiveState(of: SystemMetrics(memoryUsage: 0))
    
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
            h2 {
                "Server Health"
            }
            div(.class("stack")) {
                div(.class("text-huge")) {
                    "\(Int(state.memoryUsage)) MB"
                }
                span(.class("desc")) { "Real System Memory Usage" }
            }
            
            div(.class("mt-4 p-2 bg-slate-100 rounded text-sm font-mono")) {
                "Auto-refreshing every 2s"
            }
        }
    }
    
}

private func getSystemMemoryUsageMB() -> Double {

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
        return usedKB / 1024.0 // Convert to MB
    }
    
    return 0
}
