import Testing
import Mist
import Vapor
@testable import mottzi

@Suite("Tests")
struct MottziTests {

    @Test("Elementary flashcard add button targets its registered component")
    func elementaryFlashcardAddButtonTargetsRegisteredComponent() async throws {
        let app = try await Application.make(.testing)

        let component = FlashcardAddButtonElementary()
        let context = ComponentContext(context: ModelContext(), state: [:])
        let html: String
        do {
            html = try await component.template.render(
                context: context,
                componentName: component.name,
                using: app
            )
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()

        #expect(html.contains("mist-component=\"\(component.name)\""))
        #expect(html.contains("mist-action=\"CreateCardAction\""))
    }

    @Test("Dummy test #1 (will pass)")
    func dummyTest() {
        #expect(1 + 1 == 2)
    }
    
    @Test("Dummy test #2 (will pass)")
    func dummyTest2() {
        #expect(2 + 2 == 4)
    }
     
}
