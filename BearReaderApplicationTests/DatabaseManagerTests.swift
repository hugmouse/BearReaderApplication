//
//  DatabaseManagerTests.swift
//  BearReaderApplicationTests
//

import Testing
@preconcurrency import SQLite
@testable import BearReaderApplication

struct DatabaseManagerTests {

    /// Creates an in-memory DatabaseManager with the schema applied.
    private func makeTestManager() async throws -> DatabaseManager {
        let conn = try Connection(.inMemory)
        let manager = DatabaseManager(connection: conn)

        // Run migration to create tables
        let migration = InitialSchemaMigration()
        try migration.migrateDatabase(conn)

        return manager
    }

    @Test func saveAndRetrieveTrackedPosts() async throws {
        let manager = try await makeTestManager()

        let post = PostItem(title: "Test Post", url: "https://example.com/test", age: "2h", rating: "5")
        try await manager.saveEncounteredPost(post)

        let allPosts = try await manager.getAllTrackedPosts()
        #expect(allPosts.count == 1)
        #expect(allPosts[0].title == "Test Post")
        #expect(allPosts[0].url == "https://example.com/test")
        #expect(allPosts[0].age == "2h")
        #expect(allPosts[0].rating == "5")
    }

    @Test func toggleBookmarkFlipsState() async throws {
        let manager = try await makeTestManager()

        let post = PostItem(title: "Bookmark Test", url: "https://example.com/bm", age: "1h", rating: "3")
        try await manager.saveEncounteredPost(post)

        // Initially not bookmarked
        let initialStatus = try await manager.isPostBookmarked("https://example.com/bm")
        #expect(initialStatus == false)

        // Toggle on
        try await manager.toggleBookmark("https://example.com/bm")
        let afterToggle = try await manager.isPostBookmarked("https://example.com/bm")
        #expect(afterToggle == true)

        // Toggle off
        try await manager.toggleBookmark("https://example.com/bm")
        let afterSecondToggle = try await manager.isPostBookmarked("https://example.com/bm")
        #expect(afterSecondToggle == false)
    }

    @Test func searchPostsReturnsMatches() async throws {
        let manager = try await makeTestManager()

        let post1 = PostItem(title: "Swift Concurrency Guide", url: "https://example.com/swift", age: "3h", rating: "10")
        let post2 = PostItem(title: "Rust Ownership Model", url: "https://example.com/rust", age: "1d", rating: "8")
        try await manager.saveEncounteredPost(post1)
        try await manager.saveEncounteredPost(post2)

        let results = try await manager.searchPosts("Swift")
        #expect(results.count == 1)
        #expect(results[0].title == "Swift Concurrency Guide")
    }

    @Test func searchPostsReturnsEmptyForNoMatch() async throws {
        let manager = try await makeTestManager()

        let post = PostItem(title: "Hello World", url: "https://example.com/hello", age: "5m", rating: "1")
        try await manager.saveEncounteredPost(post)

        let results = try await manager.searchPosts("NonExistent")
        #expect(results.isEmpty)
    }
}
