import Vapor

@main struct App {
    
    static func main() async throws {
        
        let env = try Environment.detect()
        let app = try await Application.make(env)
        
        app.asyncCommands.use(SecureInputReproCommand(), as: "issue")

        try await app.execute()
        try await app.asyncShutdown()
        
    }
}

struct SecureInputReproCommand: AsyncCommand {

    struct Signature: CommandSignature {}

    var help: String { "Minimal ConsoleKit secure input repro (Linux)" }

    func run(using context: CommandContext, signature: Signature) async throws {

        context.console.output("Please enter a password: ", newLine: false)
        
        let password = context.console.input(isSecure: true)
        
        context.console.print("Your password is: \(password)")

    }
}
