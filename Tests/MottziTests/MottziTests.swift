import Testing

@Suite("Mottzi Tests")
struct MottziTests
{
    @Test("Dummy test passes")
    func dummyTest()
    {
        #expect(1 + 1 == 2)
    }
    
    @Test("Dummy test 2 fails maybe")
    func dummyTest2()
    {
        #expect(1 + 1 == 2)
    }
     
}
