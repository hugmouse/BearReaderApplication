//
//  DatabaseManager.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import Foundation
import SQLite
import SQLiteMigrationManager
import os.log

enum DatabaseError: Error {
    case documentsDirectoryNotFound
    case invalidDatabaseFile
}

actor DatabaseManager {
    static let shared = DatabaseManager()

    /// Creates a DatabaseManager with a pre-configured connection (for testing).
    init() {}

    init(connection: Connection) {
        self.db = connection
    }

    private let logger = Logger(subsystem: "BearReader", category: "DatabaseManager")
    private var db: Connection?
    
    // Schema aliases for brevity
    private var trackedPosts: SQLite.Table { DatabaseSchema.trackedPosts }
    private var trackedPostsID: SQLite.Expression<Int64> { DatabaseSchema.trackedPostsID }
    private var trackedPostsURL: SQLite.Expression<String> { DatabaseSchema.trackedPostsURL }
    private var trackedPostsTitle: SQLite.Expression<String> { DatabaseSchema.trackedPostsTitle }
    private var trackedPostsAge: SQLite.Expression<String> { DatabaseSchema.trackedPostsAge }
    private var trackedPostsRating: SQLite.Expression<String> { DatabaseSchema.trackedPostsRating }
    private var trackedPostsDomain: SQLite.Expression<String> { DatabaseSchema.trackedPostsDomain }
    private var trackedPostsWasLoaded: SQLite.Expression<Bool> { DatabaseSchema.trackedPostsWasLoaded }
    private var trackedPostsViewID: SQLite.Expression<Int> { DatabaseSchema.trackedPostsViewID }
    private var trackedPostsEncounteredAt: SQLite.Expression<Date> { DatabaseSchema.trackedPostsEncounteredAt }
    private var trackedPostsLastAccessedAt: SQLite.Expression<Date?> { DatabaseSchema.trackedPostsLastAccessedAt }
    private var trackedPostsIsBookmarked: SQLite.Expression<Bool> { DatabaseSchema.trackedPostsIsBookmarked }

    private var subscribedBlogs: SQLite.Table { DatabaseSchema.subscribedBlogs }
    private var subscribedBlogsID: SQLite.Expression<Int64> { DatabaseSchema.subscribedBlogsID }
    private var subscribedBlogsDomain: SQLite.Expression<String> { DatabaseSchema.subscribedBlogsDomain }
    private var subscribedBlogsFeedURL: SQLite.Expression<String> { DatabaseSchema.subscribedBlogsFeedURL }
    private var subscribedBlogsTitle: SQLite.Expression<String> { DatabaseSchema.subscribedBlogsTitle }
    private var subscribedBlogsSubscribedAt: SQLite.Expression<Date> { DatabaseSchema.subscribedBlogsSubscribedAt }
    private var subscribedBlogsLastFetchAt: SQLite.Expression<Date?> { DatabaseSchema.subscribedBlogsLastFetchAt }
    private var subscribedBlogsNewPostsCount: SQLite.Expression<Int> { DatabaseSchema.subscribedBlogsNewPostsCount }
    private var subscribedBlogsIsNotificationsMuted: SQLite.Expression<Bool> { DatabaseSchema.subscribedBlogsIsNotificationsMuted }

    private var browsingHistoryTable: SQLite.Table { DatabaseSchema.browsingHistoryTable }
    private var browsingHistoryID: SQLite.Expression<Int64> { DatabaseSchema.browsingHistoryID }
    private var browsingHistoryURL: SQLite.Expression<String> { DatabaseSchema.browsingHistoryURL }
    private var browsingHistoryTitle: SQLite.Expression<String> { DatabaseSchema.browsingHistoryTitle }
    private var browsingHistoryDate: SQLite.Expression<Date> { DatabaseSchema.browsingHistoryDate }
    
    private var connection: Connection {
        get throws {
            if let db = db {
                return db
            }
            
            guard let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first else {
                throw DatabaseError.documentsDirectoryNotFound
            }
            
            let dbPath = "\(path)/BearReader.sqlite3"
            
            logger.debug("Initializing database at path: \(dbPath)")
            let newConnection = try Connection(dbPath)
            try migrate(using: newConnection)
            logger.debug("Database initialized successfully")
            
            db = newConnection
            return newConnection
        }
    }
    
    private func withConnection<R>(_ body: (Connection) throws -> R) throws -> R {
        let conn = try connection
        return try body(conn)
    }

    private func trackedPostData(from row: Row) -> TrackedPostData {
        TrackedPostData(
            id: row[trackedPostsID],
            url: row[trackedPostsURL],
            title: row[trackedPostsTitle],
            age: row[trackedPostsAge],
            rating: row[trackedPostsRating],
            domain: row[trackedPostsDomain],
            wasLoaded: row[trackedPostsWasLoaded],
            viewID: row[trackedPostsViewID],
            encounteredAt: row[trackedPostsEncounteredAt],
            lastAccessedAt: row[trackedPostsLastAccessedAt],
            isBookmarked: row[trackedPostsIsBookmarked]
        )
    }

    private func migrate(using connection: Connection) throws {
        logger.debug("Starting database migration")
        
        let manager = SQLiteMigrationManager(
            db: connection,
            migrations: [InitialSchemaMigration()],
            bundle: Bundle.main
        )
        
        if !manager.hasMigrationsTable() {
            logger.debug("Creating migrations table")
            try manager.createMigrationsTable()
        }
        
        if manager.needsMigration() {
            logger.debug("Pending migrations: \(manager.pendingMigrations())")
            try manager.migrateDatabase()
            logger.debug("Database migration completed successfully")
        } else {
            logger.debug("No migrations needed")
        }
    }
    
    
    func saveEncounteredPost(_ post: PostItem) throws {
        let conn = try connection
        logger.debug("Saving encountered post: \(post.title) at \(post.url)")
        let insert = trackedPosts.insert(or: .ignore,
                                         trackedPostsURL <- post.url,
                                         trackedPostsTitle <- post.title,
                                         trackedPostsAge <- post.age,
                                         trackedPostsRating <- post.rating,
                                         trackedPostsDomain <- post.domain,
                                         trackedPostsEncounteredAt <- Date(),
                                         trackedPostsViewID <- 0,
        )
        try conn.run(insert)
        logger.debug("Post saved successfully: \(post.url)")
    }
    
    func saveEncounteredPosts(_ posts: [PostItem]) throws {
        logger.debug("Saving encountered posts")
        try withConnection { conn in
            let encounteredAt = Date()
            try conn.transaction {
                let rows = posts.map { post in
                    [
                        trackedPostsURL <- post.url,
                        trackedPostsTitle <- post.title,
                        trackedPostsAge <- post.age,
                        trackedPostsRating <- post.rating,
                        trackedPostsDomain <- post.domain,
                        trackedPostsEncounteredAt <- encounteredAt,
                        trackedPostsViewID <- 0
                    ]
                }
                try conn.run(trackedPosts.insertMany(or: .ignore, rows))
            }
        }
        logger.debug("Saved encountered posts, amount: \(posts.count)")
    }
    
    func markAsLoaded(_ postUrl: String) throws {
        let conn = try connection
        logger.debug("Marking post as loaded: \(postUrl)")
        let post = trackedPosts.filter(trackedPostsURL == postUrl)
        try conn.run(post.update(
            trackedPostsWasLoaded <- true,
            trackedPostsLastAccessedAt <- Date()
        ))
        logger.debug("Post marked as loaded: \(postUrl)")
    }
    
    func updateViewID(_ postUrl: String, viewID: Int) throws {
        let conn = try connection
        logger.debug("Updating view ID for \(postUrl): \(viewID)")
        let post = trackedPosts.filter(trackedPostsURL == postUrl)
        try conn.run(post.update(
            self.trackedPostsViewID <- viewID,
            trackedPostsLastAccessedAt <- Date()
        ))
        logger.debug("View ID updated for \(postUrl)")
    }
    
    
    func getViewID(_ postUrl: String) throws -> Int? {
        let conn = try connection
        logger.debug("Getting view ID for: \(postUrl)")
        let query = trackedPosts.filter(trackedPostsURL == postUrl).limit(1)
        for row in try conn.prepare(query) {
            let id = row[trackedPostsViewID]
            logger.debug("Retrieved view ID for \(postUrl): \(String(describing: id))")
            return id
        }
        logger.debug("No view ID found for \(postUrl), returning nil")
        return nil
    }
    
    func searchPosts(_ query: String) throws -> [TrackedPostData] {
        let conn = try connection
        var results: [TrackedPostData] = []
        
        logger.debug("Searching posts with query: \(query)")
        let searchQuery = trackedPosts.filter(trackedPostsTitle.like("%\(query)%") || trackedPostsDomain.like("%\(query)%"))
            .order(trackedPostsLastAccessedAt.desc)
        
        for row in try conn.prepare(searchQuery) {
            results.append(trackedPostData(from: row))
        }
        logger.debug("Search completed. Found \(results.count) posts for query: \(query)")
        
        return results
    }
    
    func getReadPosts() throws -> [TrackedPostData] {
        let conn = try connection
        var results: [TrackedPostData] = []
        
        logger.debug("Fetching read posts")
        let query = trackedPosts.filter(trackedPostsViewID > 0).order(trackedPostsLastAccessedAt.desc)
        
        for row in try conn.prepare(query) {
            results.append(trackedPostData(from: row))
        }
        logger.debug("Retrieved \(results.count) read posts")
        
        return results
    }
    
    func removeTrackedPost(_ postUrl: String) throws {
        let conn = try connection
        logger.debug("Removing tracked post: \(postUrl)")
        let post = trackedPosts.filter(trackedPostsURL == postUrl)
        try conn.run(post.delete())
        logger.debug("Tracked post removed: \(postUrl)")
    }
    
    func getAllTrackedPosts() throws -> [TrackedPostData] {
        let conn = try connection
        var results: [TrackedPostData] = []
        
        logger.debug("Fetching all tracked posts")
        let query = trackedPosts.order(trackedPostsEncounteredAt.desc)
        
        for row in try conn.prepare(query) {
            results.append(trackedPostData(from: row))
        }
        logger.debug("Retrieved \(results.count) total tracked posts")
        
        return results
    }
    
    func getTrackedPostUrls(for domainFilter: String) throws -> Set<String> {
        let conn = try connection
        logger.debug("Fetching tracked post URLs for domain: \(domainFilter)")
        
        let query = trackedPosts
            .select(trackedPostsURL)
            .filter(trackedPostsDomain == domainFilter)
        
        var urls = Set<String>()
        for row in try conn.prepare(query) {
            urls.insert(row[trackedPostsURL])
        }
        
        logger.debug("Retrieved \(urls.count) tracked post URLs for domain: \(domainFilter)")
        return urls
    }
    
    func clearAllData() throws {
        let conn = try connection
        logger.debug("Clearing all data from tracked_posts table")
        try conn.run(trackedPosts.delete())
        logger.debug("All data cleared successfully")
    }
    
    func toggleBookmark(_ postUrl: String) throws {
        let conn = try connection
        logger.debug("Toggling bookmark for: \(postUrl)")
        
        let post = trackedPosts.filter(trackedPostsURL == postUrl)
        let currentBookmarkStatus = try conn.pluck(post.select(trackedPostsIsBookmarked))
        let newBookmarkStatus = !(currentBookmarkStatus?[trackedPostsIsBookmarked] ?? false)
        
        try conn.run(post.update(trackedPostsIsBookmarked <- newBookmarkStatus))
        logger.debug("Bookmark toggled for \(postUrl): \(newBookmarkStatus)")
    }
    
    func isPostBookmarked(_ postUrl: String) throws -> Bool {
        let conn = try connection
        logger.debug("Checking bookmark status for: \(postUrl)")
        
        let post = trackedPosts.filter(trackedPostsURL == postUrl)
        if let row = try conn.pluck(post.select(trackedPostsIsBookmarked)) {
            return row[trackedPostsIsBookmarked]
        }
        return false
    }
    
    func getBookmarkedPosts() throws -> [TrackedPostData] {
        let conn = try connection
        var results: [TrackedPostData] = []
        
        logger.debug("Fetching bookmarked posts")
        let query = trackedPosts.filter(trackedPostsIsBookmarked == true).order(trackedPostsLastAccessedAt.desc)
        
        for row in try conn.prepare(query) {
            results.append(trackedPostData(from: row))
        }
        logger.debug("Retrieved \(results.count) bookmarked posts")
        
        return results
    }
    
    // MARK: - Blog Subscription
    
    func subscribeToBlog(domain: String, feedUrl: String, blogTitle titleValue: String) throws {
        let conn = try connection
        logger.debug("Subscribing to blog: \(domain)")
        let insert = subscribedBlogs.insert(or: .replace,
                                            subscribedBlogsDomain <- domain,
                                            subscribedBlogsFeedURL <- feedUrl,
                                            subscribedBlogsTitle <- titleValue,
                                            subscribedBlogsSubscribedAt <- Date(),
                                            subscribedBlogsLastFetchAt <- nil
        )
        try conn.run(insert)
        logger.debug("Subscribed to blog: \(domain)")
    }

    func restoreBlog(_ blog: BlogSubscription) throws {
        let conn = try connection
        logger.debug("Restoring blog: \(blog.domain)")
        let insert = subscribedBlogs.insert(or: .replace,
                                            subscribedBlogsDomain <- blog.domain,
                                            subscribedBlogsFeedURL <- blog.feedUrl,
                                            subscribedBlogsTitle <- blog.blogTitle,
                                            subscribedBlogsSubscribedAt <- blog.subscribedAt,
                                            subscribedBlogsLastFetchAt <- blog.lastFetchedAt,
                                            subscribedBlogsNewPostsCount <- blog.newPostsCount,
                                            subscribedBlogsIsNotificationsMuted <- blog.isNotificationsMuted
        )
        try conn.run(insert)
        logger.debug("Restored blog: \(blog.domain)")
    }
    
    func unsubscribeFromBlog(domain: String) throws {
        let conn = try connection
        logger.debug("Unsubscribing from blog: \(domain)")
        let blog = subscribedBlogs.filter(subscribedBlogsDomain == domain)
        try conn.run(blog.delete())
        logger.debug("Unsubscribed from blog: \(domain)")
    }
    
    func isSubscribedToBlog(domain: String) throws -> Bool {
        let conn = try connection
        logger.debug("Checking subscription status for: \(domain)")
        let query = subscribedBlogs.filter(subscribedBlogsDomain == domain).limit(1)
        let count = try conn.scalar(query.count)
        logger.debug("Subscription status for \(domain): \(count > 0)")
        return count > 0
    }
    
    func getSubscribedBlogs() throws -> [BlogSubscription] {
        let conn = try connection
        var results: [BlogSubscription] = []
        
        logger.debug("Fetching subscribed blogs")
        let query = subscribedBlogs.order(subscribedBlogsSubscribedAt.desc)
        
        for row in try conn.prepare(query) {
            let subscription = BlogSubscription(
                id: row[subscribedBlogsID],
                domain: row[subscribedBlogsDomain],
                feedUrl: row[subscribedBlogsFeedURL],
                blogTitle: row[subscribedBlogsTitle],
                subscribedAt: row[subscribedBlogsSubscribedAt],
                lastFetchedAt: row[subscribedBlogsLastFetchAt],
                newPostsCount: row[subscribedBlogsNewPostsCount],
                isNotificationsMuted: row[subscribedBlogsIsNotificationsMuted]
            )
            results.append(subscription)
        }
        logger.debug("Retrieved \(results.count) subscribed blogs")
        
        return results
    }
    
    func updateBlogLastFetched(domain: String) throws {
        let conn = try connection
        logger.debug("Updating last fetched time for blog: \(domain)")
        let blog = subscribedBlogs.filter(subscribedBlogsDomain == domain)
        try conn.run(blog.update(subscribedBlogsLastFetchAt <- Date()))
        logger.debug("Updated last fetched time for blog: \(domain)")
    }
    
    func incrementNewPostsCount(domain: String, by count: Int) throws {
        let conn = try connection
        logger.debug("Incrementing new posts count for blog: \(domain) by \(count)")
        let blog = subscribedBlogs.filter(subscribedBlogsDomain == domain)
        
        if let currentRow = try conn.pluck(blog) {
            let currentCount = currentRow[subscribedBlogsNewPostsCount]
            try conn.run(blog.update(subscribedBlogsNewPostsCount <- currentCount + count))
            logger.debug("New posts count updated for \(domain): \(currentCount + count)")
        }
    }
    
    func resetNewPostsCount(domain: String) throws {
        let conn = try connection
        logger.debug("Resetting new posts count for blog: \(domain)")
        let blog = subscribedBlogs.filter(subscribedBlogsDomain == domain)
        try conn.run(blog.update(subscribedBlogsNewPostsCount <- 0))
        logger.debug("New posts count reset for \(domain)")
    }
    
    func getNewPostsCount(domain: String) throws -> Int {
        let conn = try connection
        logger.debug("Getting new posts count for blog: \(domain)")
        let blog = subscribedBlogs.filter(subscribedBlogsDomain == domain)
        
        if let row = try conn.pluck(blog) {
            return row[subscribedBlogsNewPostsCount]
        }
        return 0
    }

    func toggleNotificationsMuted(domain: String) throws {
        let conn = try connection
        logger.debug("Toggling notifications muted for blog: \(domain)")
        let blog = subscribedBlogs.filter(subscribedBlogsDomain == domain)
        
        if let currentRow = try conn.pluck(blog) {
            let currentMuted = currentRow[subscribedBlogsIsNotificationsMuted]
            try conn.run(blog.update(subscribedBlogsIsNotificationsMuted <- !currentMuted))
            logger.debug("Notifications muted toggled for \(domain): \(!currentMuted)")
        }
    }
    
    func setNotificationsMuted(domain: String, muted: Bool) throws {
        let conn = try connection
        logger.debug("Setting notifications muted for blog: \(domain) to \(muted)")
        let blog = subscribedBlogs.filter(subscribedBlogsDomain == domain)
        try conn.run(blog.update(subscribedBlogsIsNotificationsMuted <- muted))
        logger.debug("Notifications muted set for \(domain): \(muted)")
    }
    
    func isNotificationsMuted(domain: String) throws -> Bool {
        let conn = try connection
        logger.debug("Checking if notifications muted for blog: \(domain)")
        let blog = subscribedBlogs.filter(subscribedBlogsDomain == domain)
        
        if let row = try conn.pluck(blog) {
            return row[subscribedBlogsIsNotificationsMuted]
        }
        return false
    }
    
    // MARK: - Database Import

    func replaceDatabase(with sourceURL: URL) throws {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first else {
            throw DatabaseError.documentsDirectoryNotFound
        }

        let dbPath = "\(documentsPath)/BearReader.sqlite3"

        // Validate the imported file has expected tables
        let importedConnection = try Connection(sourceURL.path)
        let tables = try importedConnection.prepare("SELECT name FROM sqlite_master WHERE type='table'")
        var tableNames = Set<String>()
        for row in tables {
            if let name = row[0] as? String {
                tableNames.insert(name)
            }
        }

        let requiredTables: Set<String> = ["tracked_posts", "subscribed_blogs", "visit_history"]
        guard requiredTables.isSubset(of: tableNames) else {
            logger.error("Imported database missing required tables. Found: \(tableNames)")
            throw DatabaseError.invalidDatabaseFile
        }

        // Close current connection
        db = nil
        logger.debug("Closed current database connection for import")

        // Replace the database file
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: dbPath) {
            try fileManager.removeItem(atPath: dbPath)
        }
        try fileManager.copyItem(atPath: sourceURL.path, toPath: dbPath)

        logger.debug("Database replaced successfully from: \(sourceURL.path)")

        // Force reconnection (will run migrations on next access)
        db = nil
    }

    // MARK: - Browsing history related things
    
    func addToBrowsingHistory(_url: String, _title: String) throws {
        let conn = try connection
        logger.debug("Adding an entry to browsing history")
        let insert = browsingHistoryTable.insert(or: .ignore,
                                                 browsingHistoryURL <- _url,
                                                 browsingHistoryTitle <- _title,
                                                 browsingHistoryDate <- Date.now,
        )
        try conn.run(insert)
    }
    
    func deleteItemFromBrowsingHistory(id: Int64) throws {
        let conn = try connection
        let post = browsingHistoryTable.filter(browsingHistoryID == id)
        try conn.run(post.delete())
    }
    
    func getBrowsingHistory() throws -> [BrowsingHistory] {
        let conn = try connection
        
        var results: [BrowsingHistory] = []
        
        logger.debug("Fetching browsing history")
        let query = browsingHistoryTable.order(browsingHistoryDate.desc)
        
        for row in try conn.prepare(query) {
            let subscription = BrowsingHistory(
                id: row[browsingHistoryID],
                title: row[browsingHistoryTitle],
                url: row[browsingHistoryURL],
                date: row[browsingHistoryDate],
            )
            results.append(subscription)
        }
        logger.debug("Retrieved \(results.count) entries in browsing history")

        return results
    }

    func getPostStatusAndRecordHistory(
        postUrl: String,
        postTitle: String,
        blogDomain: String
    ) throws -> PostViewStatus {
        let conn = try connection

        let post = trackedPosts.filter(trackedPostsURL == postUrl)
        let isBookmarked: Bool
        if let row = try conn.pluck(post.select(trackedPostsIsBookmarked)) {
            isBookmarked = row[trackedPostsIsBookmarked]
        } else {
            isBookmarked = false
        }

        let subscriptionQuery = subscribedBlogs.filter(subscribedBlogsDomain == blogDomain).limit(1)
        let isSubscribed = try conn.scalar(subscriptionQuery.count) > 0

        let insert = browsingHistoryTable.insert(or: .ignore,
                                                 browsingHistoryURL <- postUrl,
                                                 browsingHistoryTitle <- postTitle,
                                                 browsingHistoryDate <- Date.now)
        try conn.run(insert)

        return PostViewStatus(isBookmarked: isBookmarked, isSubscribed: isSubscribed)
    }

}

struct PostViewStatus {
    let isBookmarked: Bool
    let isSubscribed: Bool
}

struct TrackedPostData {
    let id: Int64
    let url: String
    let title: String
    let age: String
    let rating: String
    let domain: String
    let wasLoaded: Bool
    let viewID: Int
    let encounteredAt: Date
    let lastAccessedAt: Date?
    let isBookmarked: Bool
    
    var isRead: Bool {
        viewID > 1
    }
    
    var toPost: PostItem {
        return PostItem(title: title, url: url, age: age, rating: rating)
    }
}
