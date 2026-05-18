import Testing

@Suite("Mottzi Tests")
struct MottziTests
{
    @Test("Dummy test passes")
    func dummyTest()
    {
        #expect(1 + 1 == 2)
    }
}
