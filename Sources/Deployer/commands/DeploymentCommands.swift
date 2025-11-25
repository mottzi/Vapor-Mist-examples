import Vapor

struct HelloCommand: AsyncCommand {
    struct Signature: CommandSignature { }
    
    var help: String {
        "Says hello"
    }
    
    func run(using context: CommandContext, signature: Signature) async throws {
        context.console.print("Hello, world!")
    }
}
