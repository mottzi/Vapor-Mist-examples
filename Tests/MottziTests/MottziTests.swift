import Testing

@Suite("Tests")
struct MottziTests {

    @Test("Dummy test #1 (will pass)")
    func dummyTest() {
        #expect(1 + 1 == 2)
    }
    
    @Test("Dummy test #2 (will pass)")
    func dummyTest2() {
        #expect(2 + 2 == 4)
    }
     
}
