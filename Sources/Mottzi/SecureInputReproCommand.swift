import Vapor

struct SecureInputReproCommand: AsyncCommand {
    
    struct Signature: CommandSignature {}

    var help: String {
        "Repro: secure ConsoleKit input on Linux."
    }

    @MainActor
    func run(using context: CommandContext, signature: Signature) async throws {
        let console = context.console

        console.print("")
        console.print("=== Secure input repro ===")
        console.print("Use a real TTY (interactive ssh). Step [1] is plain readLine; step [2] is secure.")

        console.print("")
        console.print("[1] Non-secure:")
        console.output("  Visible: ".consoleText(), newLine: false)
        _ = console.input(isSecure: false)

        console.print("")
        console.print("[2] Secure (MainActor — still SIGILL on Ubuntu 24.04 in practice; compare to bare `input(isSecure:)` for upstream):")
        console.output("  Password: ".consoleText(), newLine: false)
        _ = await MainActor.run {
            console.input(isSecure: true)
        }

        console.print("")
        console.print("OK — finished without trapping.")
    }
}
