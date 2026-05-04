import Vapor
import Mist
import Elementary
import Foundation

struct SystemMemoryComponent: LiveComponent {

    var actions: [any Action] { [StressTestAction()] }

    struct SystemMetrics: ComponentData {
        var memoryUsage: Int
        var cpuLoad: Double
        var connectedClients: Int
    }
    
    let state = LiveState(of: SystemMetrics(memoryUsage: getSystemMemoryUsageMB(), cpuLoad: getInstantCPULoad(), connectedClients: 0))
    
    var refreshInterval: Duration { .seconds(2) }

    func refresh(app: Application) async {
        let realUsageMB = getSystemMemoryUsageMB()
        let realCpuLoad = getInstantCPULoad()
        let clients = await getConnectedClients(app: app)
        await state.set(.init(memoryUsage: realUsageMB, cpuLoad: realCpuLoad, connectedClients: clients))
    }

    func body(state: SystemMetrics) -> some HTML {
        div(
            .mistComponent(value: name),
            .class("stack"),
            .style("gap: 2rem; align-items: center;")
        ) {
            div(.class("inline"), .style("justify-content: center; gap: 1rem; flex-wrap: wrap; width: 100%;")) {
                // Memory Card
                div(.class("card stack text-center"), .style("flex: 1; min-width: 180px; padding: 1.5rem;")) {
                    div(.class("stack"), .style("gap: 0.25rem; align-items: center;")) {
                        h2(.style("margin: 0; font-size: 1.1rem; color: var(--text-secondary);")) { "Memory Usage" }
                    }
                    div(.class("text-huge"), .style("font-size: 2rem; margin-top: 0.5rem;")) {
                        "\(state.memoryUsage) MB"
                    }
                }
                
                // CPU Card
                div(.class("card stack text-center"), .style("flex: 1; min-width: 180px; padding: 1.5rem;")) {
                    div(.class("stack"), .style("gap: 0.25rem; align-items: center;")) {
                        h2(.style("margin: 0; font-size: 1.1rem; color: var(--text-secondary);")) { "CPU Load" }
                    }
                    div(.class("text-huge"), .style("font-size: 2rem; margin-top: 0.5rem;")) {
                        "\(String(format: "%.1f", state.cpuLoad))%"
                    }
                }
                
                // Clients Card
                div(.class("card stack text-center"), .style("flex: 1; min-width: 180px; padding: 1.5rem;")) {
                    div(.class("stack"), .style("gap: 0.25rem; align-items: center;")) {
                        h2(.style("margin: 0; font-size: 1.1rem; color: var(--text-secondary);")) { "Active Clients" }
                    }
                    div(.class("text-huge"), .style("font-size: 2rem; margin-top: 0.5rem; color: var(--color-accent);")) {
                        "\(state.connectedClients)"
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

private struct CPUStat {
    var total: Double
    var active: Double
}
private var lastCPUStat: CPUStat? = nil

private func getInstantCPULoad() -> Double {
    guard let stat = try? String(contentsOfFile: "/proc/stat", encoding: .utf8) else {
        #if os(macOS)
        // Fallback for local testing on macOS where /proc/stat doesn't exist
        return Double.random(in: 2.0...15.0)
        #else
        return 0.0
        #endif
    }
    
    guard let firstLine = stat.split(separator: "\n").first else { return 0.0 }
    let parts = firstLine.split(separator: " ", omittingEmptySubsequences: true)
    guard parts.count >= 8, parts[0] == "cpu" else { return 0.0 }
    
    let values = parts.dropFirst().compactMap { Double($0) }
    guard values.count >= 7 else { return 0.0 }
    
    let user = values[0]
    let nice = values[1]
    let system = values[2]
    let idle = values[3]
    let iowait = values[4]
    let irq = values[5]
    let softirq = values[6]
    
    let totalIdle = idle + iowait
    let active = user + nice + system + irq + softirq
    let total = totalIdle + active
    
    let currentStat = CPUStat(total: total, active: active)
    defer { lastCPUStat = currentStat }
    
    guard let last = lastCPUStat else { return 0.0 }
    
    let totalDiff = total - last.total
    let activeDiff = active - last.active
    
    if totalDiff > 0 {
        return (activeDiff / totalDiff) * 100.0
    }
    return 0.0
}

private func getConnectedClients(app: Application) async -> Int {
    // Reflect into the Mist Clients actor to read the internal registry count
    let mirror = Mirror(reflecting: app.mist.clients)
    if let clientsArray = mirror.descendant("clients") as? [Any] {
        return clientsArray.count
    }
    return 1
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