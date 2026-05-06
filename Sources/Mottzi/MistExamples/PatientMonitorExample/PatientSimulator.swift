import Vapor
import Fluent
import Mist

struct PatientSimulator {
    static func start(app: Application) {
        Task {
            app.logger.info("Starting Patient Monitor Simulator...")
            
            while !Task.isCancelled {
                // Sleep for 1-3 seconds
                let sleepSeconds = Double.random(in: 1.0...3.0)
                try? await Task.sleep(nanoseconds: UInt64(sleepSeconds * 1_000_000_000))
                
                do {
                    // Fetch all vitals
                    let allVitals = try await Vitals.query(on: app.db).all()
                    guard !allVitals.isEmpty else { continue }
                    
                    // Pick a random number of patients to update (1 to all)
                    let count = Int.random(in: 1...allVitals.count)
                    let toUpdate = allVitals.shuffled().prefix(count)
                    
                    for vitals in toUpdate {
                        // Randomly fluctuate or trigger a warning
                        let chance = Double.random(in: 0...1)
                        
                        if chance > 0.9 {
                            // 10% chance of a "Spike" (Emergency)
                            vitals.heartRate = Int.random(in: 110...140)
                            vitals.oxygenLevel = Int.random(in: 88...92)
                            vitals.statusColor = "red"
                        } else if chance > 0.7 {
                            // 20% chance of a "Warning"
                            vitals.heartRate = Int.random(in: 90...105)
                            vitals.oxygenLevel = Int.random(in: 93...96)
                            vitals.statusColor = "yellow"
                        } else {
                            // 70% chance of "Normal" fluctuation
                            vitals.heartRate = Int.random(in: 68...82)
                            vitals.oxygenLevel = Int.random(in: 97...100)
                            vitals.statusColor = "green"
                        }
                        
                        try await vitals.save(on: app.db)
                    }
                } catch {
                    app.logger.error("Simulator error: \(error)")
                }
            }
        }
    }
}
