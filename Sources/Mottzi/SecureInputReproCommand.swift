import Vapor

/// Minimal AsyncCommand hitting `Terminal.input(isSecure: true)` (readpassphrase on Linux).
struct SecureInputReproCommand: AsyncCommand {
    
    struct Signature: CommandSignature {}

    var help: String { "Repro: secure ConsoleKit input on Linux." }

    func run(using context: CommandContext, signature: Signature) async throws {
        
        let console = context.console
        
        console.print("")
        console.print("[1] Non-secure prompt:")
        console.output("  Visible: ".consoleText(), newLine: false)
        _ = console.input(isSecure: false)

        console.print("")
        console.print("[2] Secure (same pattern as Deployer secret prompts):")
        console.output("  Password: ".consoleText(), newLine: false)
        _ = console.input(isSecure: true)

        console.print("")
        console.print("OK — finished without trapping.")
    }
}
