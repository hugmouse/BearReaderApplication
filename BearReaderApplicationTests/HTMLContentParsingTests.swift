import Testing
@testable import BearReaderApplication

struct HTMLContentParsingTests {
    @Test func topLevelSmallParsesAsTextElement() async throws {
        let service = BearBlogService(settings: SettingsHelper.getDefaultSettings())
        let content = try #require(await service.parseMainContentForTesting(html: """
        <html>
            <body>
                <main>
                    <small>Published yesterday</small>
                </main>
            </body>
        </html>
        """))

        #expect(content.elements.count == 1)
        guard case .text(let text) = content.elements[0] else {
            Issue.record("Expected <small> to parse as a text element")
            return
        }
        #expect(String(text.characters).contains("Published yesterday"))
    }

    @Test func blockquoteWithParagraphParsesAsBlockquote() async throws {
        let service = BearBlogService(settings: SettingsHelper.getDefaultSettings())
        let content = try #require(await service.parseMainContentForTesting(html: """
        <html>
            <body>
                <main>
                    <blockquote><p>Quoted paragraph</p></blockquote>
                </main>
            </body>
        </html>
        """))

        #expect(content.elements.count == 1)
        guard case .blockquote(let quoteElements) = content.elements[0] else {
            Issue.record("Expected <blockquote> to parse as a blockquote element")
            return
        }
        #expect(quoteElements.count == 1)
        guard case .text(let text) = quoteElements[0] else {
            Issue.record("Expected paragraph inside blockquote to parse as text")
            return
        }
        #expect(String(text.characters).contains("Quoted paragraph"))
    }

    @Test func blockquoteWithDirectTextIsNotDropped() async throws {
        let service = BearBlogService(settings: SettingsHelper.getDefaultSettings())
        let content = try #require(await service.parseMainContentForTesting(html: """
        <html>
            <body>
                <main>
                    <blockquote>Direct <small>quoted</small> text</blockquote>
                </main>
            </body>
        </html>
        """))

        #expect(content.elements.count == 1)
        guard case .blockquote(let quoteElements) = content.elements[0] else {
            Issue.record("Expected direct-text blockquote to parse as a blockquote element")
            return
        }
        #expect(quoteElements.count == 1)
        guard case .text(let text) = quoteElements[0] else {
            Issue.record("Expected direct text inside blockquote to parse as text")
            return
        }
        let renderedText = String(text.characters)
        #expect(renderedText.contains("Direct"))
        #expect(renderedText.contains("quoted"))
        #expect(renderedText.contains("text"))
    }
}
