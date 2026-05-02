import Elementary

struct MistExamplesIndexPage: HTMLDocument {
    
    var title = "Mist Examples"

    var head: some HTML { EmptyHTML() }
    
    var body: some HTML {
        main {
            h1 { "Mist Examples" }
            ul {
                li { a(.href("/FlashcardExample")) { "Flashcard Example" } }
                li { a(.href("/CounterExample")) { "Counter Example" } }
            }
        }
    }
    
}
