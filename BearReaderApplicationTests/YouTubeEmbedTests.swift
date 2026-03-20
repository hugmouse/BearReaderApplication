//
//  YouTubeEmbedTests.swift
//  BearReaderApplicationTests
//

import Testing
@testable import BearReaderApplication

struct YouTubeEmbedTests {

    @Test func validEmbedURLReturnsEmbed() {
        let result = parseYouTubeEmbed(
            from: "https://www.youtube.com/embed/dQw4w9WgXcQ",
            title: "Test Video"
        )
        #expect(result != nil)
        #expect(result?.videoID == "dQw4w9WgXcQ")
        #expect(result?.title == "Test Video")
        #expect(result?.embedURL.absoluteString == "https://www.youtube.com/embed/dQw4w9WgXcQ")
        #expect(result?.thumbnailURL.absoluteString == "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg")
    }

    @Test func validNoCookieHostReturnsEmbed() {
        let result = parseYouTubeEmbed(
            from: "https://www.youtube-nocookie.com/embed/abc123-_X",
            title: nil
        )
        #expect(result != nil)
        #expect(result?.videoID == "abc123-_X")
        #expect(result?.title == "Video")
    }

    @Test func invalidCharactersInVideoIDReturnsNil() {
        let result = parseYouTubeEmbed(
            from: "https://www.youtube.com/embed/bad<script>id",
            title: "Test"
        )
        #expect(result == nil)
    }

    @Test func emptyVideoIDReturnsNil() {
        let result = parseYouTubeEmbed(
            from: "https://www.youtube.com/embed/",
            title: "Test"
        )
        #expect(result == nil)
    }

    @Test func nonHTTPSSchemeReturnsNil() {
        let result = parseYouTubeEmbed(
            from: "http://www.youtube.com/embed/dQw4w9WgXcQ",
            title: "Test"
        )
        #expect(result == nil)
    }

    @Test func nonYouTubeHostReturnsNil() {
        let result = parseYouTubeEmbed(
            from: "https://www.evil.com/embed/dQw4w9WgXcQ",
            title: "Test"
        )
        #expect(result == nil)
    }

    @Test func missingEmbedPathReturnsNil() {
        let result = parseYouTubeEmbed(
            from: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            title: "Test"
        )
        #expect(result == nil)
    }

    @Test func whitespaceOnlyTitleFallsBackToDefault() {
        let result = parseYouTubeEmbed(
            from: "https://www.youtube.com/embed/dQw4w9WgXcQ",
            title: "   "
        )
        #expect(result != nil)
        #expect(result?.title == "Video")
    }
}
