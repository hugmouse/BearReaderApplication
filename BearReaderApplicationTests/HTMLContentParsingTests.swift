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

    @Test func k10sFigureBodyImageParsesAsImageElement() async throws {
        let service = BearBlogService(settings: SettingsHelper.getDefaultSettings())
        let content = try #require(await service.parseMainContentForTesting(html: """
        <html>
            <body>
                <main>
                    <p>Humans intervention is still needed as of 10/05/2026.</p>
                    <figure style="text-align: center; margin: 2em 0;">
                        <img
                            src="https://bear-images.sfo2.cdn.digitaloceanspaces.com/k10s/cat-illustration3.webp"
                            style="border-radius: 6px; box-shadow: 0 8px 32px rgba(0,0,0,0.6);"
                        />
                        <figcaption>
                            Art by human: <a href="https://www.instagram.com/yogyata.aj/" target="_blank">Yogyata A Joshi</a>
                        </figcaption>
                    </figure>
                    <p>Here is k10s.</p>
                </main>
            </body>
        </html>
        """))

        guard let imageElement = content.elements.first(where: { element in
            if case .image = element { return true }
            return false
        }) else {
            Issue.record("Expected the k10s body image inside <figure> to parse as an image element")
            return
        }

        guard case .image(let image) = imageElement else {
            Issue.record("Expected matched element to be an image")
            return
        }
        #expect(image.url == "https://bear-images.sfo2.cdn.digitaloceanspaces.com/k10s/cat-illustration3.webp")
        #expect(image.altText.isEmpty)
        #expect(image.needsPadding)

        guard let figcaptionElement = content.elements.first(where: { element in
            if case .figcaption = element { return true }
            return false
        }) else {
            Issue.record("Expected the k10s figure caption to parse as a figcaption element")
            return
        }

        guard case .figcaption(let caption) = figcaptionElement else {
            Issue.record("Expected matched element to be a figcaption")
            return
        }
        let captionText = String(caption.characters)
        #expect(captionText.contains("Art by human:"))
        #expect(captionText.contains("Yogyata A Joshi"))
    }
}
