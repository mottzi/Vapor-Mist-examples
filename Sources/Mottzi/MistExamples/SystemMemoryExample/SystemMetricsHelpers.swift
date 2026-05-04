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
    guard let meminfo = try? String(contentsOfFile: "/proc/meminfo") else {
        return 0
    }

    var total = 0.0, free = 0.0, buffers = 0.0, cached = 0.0, reclaimable = 0.0

    for line in meminfo.split(separator: "\n") {
        let parts = line.split(whereSeparator: { $0 == " " })
        guard parts.count >= 2, let kb = Double(parts[1]) else { continue }

        switch parts[0] {
        case "MemTotal:": total = kb
        case "MemFree:": free = kb
        case "Buffers:": buffers = kb
        case "Cached:": cached = kb
        case "SReclaimable:": reclaimable = kb
        default: break
        }
    }

    let used = total - free - buffers - cached - reclaimable
    return Int(used / 1024)
}
