import Foundation

func getSystemLoadAverage() -> Double {
    guard let loadavg = try? String(contentsOfFile: "/proc/loadavg", encoding: .utf8) else {
        return 0.0
    }

    let parts = loadavg.split(separator: " ", omittingEmptySubsequences: true)
    if parts.count >= 1, let load = Double(parts[0]) {
        return load
    }

    return 0.0
}

func getSystemMemoryUsageMB() -> Int {
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
        return Int(usedKB / 1024.0)
    }

    return 0
}
