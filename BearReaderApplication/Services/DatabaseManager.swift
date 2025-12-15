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
import os.log

actor DatabaseManager {
    static let shared = DatabaseManager()
    
    private let logger = Logger(subsystem: "BearReader", category: "DatabaseManager")
    private var db: Connection?
    
    private let trackedPosts = Table("tracked_posts")
    private let trackedPostsID = Expression<Int64>("id")
    private let trackedPostsURL = Expression<String>("url")
    private let trackedPostsTitle = Expression<String>("title")
    private let trackedPostsAge = Expression<String>("age")
    private let trackedPostsRating = Expression<String>("rating")
    private let trackedPostsDomain = Expression<String>("domain")
    private let trackedPostsWasLoaded = Expression<Bool>("was_loaded")
    private let trackedPostsViewID = Expression<Int>("view_id") // used to restore scrolling position
    private let trackedPostsEncounteredAt = Expression<Date>("encountered_at")
    private let trackedPostsLastAccessedAt = Expression<Date?>("last_accessed_at")
    private let trackedPostsIsBookmarked = Expression<Bool>("is_bookmarked")
    
    private let subscribedBlogs = Table("subscribed_blogs")
    private let subscribedBlogsID = Expression<Int64>("id")
    private let subscribedBlogsDomain = Expression<String>("domain")
    private let subscribedBlogsFeedURL = Expression<String>("feed_url")
    private let subscribedBlogsTitle = Expression<String>("blog_title")
    private let subscribedBlogsSubscribedAt = Expression<Date>("subscribed_at")
    private let subscribedBlogsLastFetchAt = Expression<Date?>("last_fetched_at")
    private let subscribedBlogsNewPostsCount = Expression<Int>("new_posts_count")
    
    private let browsingHistoryTable = Table("visit_history")
    private let browsingHistoryID = Expression<Int64>("id")
    private let browsingHistoryURL = Expression<String>("url")
    private let browsingHistoryTitle = Expression<String>("title")
    private let browsingHistoryDate = Expression<Date>("date")
    
    private var connection: Connection {
        get throws {
            if let db = db {
                return db
            }
            
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!
            
            let dbPath = "\(path)/BearReader.sqlite3"
            
            logger.debug("Initializing database at path: \(dbPath)")
            let newConnection = try Connection(dbPath)
            try createTable(using: newConnection)
            logger.debug("Database initialized successfully")
            
            db = newConnection
            return newConnection
        }
    }
    
    private func withConnection<R>(_ body: (Connection) throws -> R) throws -> R {
        let conn = try connection
        return try body(conn)
    }
    
    private func createTable(using connection: Connection) throws {
        logger.debug("Creating tracked_posts table")
        try connection.run(trackedPosts.create(ifNotExists: true) { t in
            t.column(trackedPostsID, primaryKey: .autoincrement)
            t.column(trackedPostsURL, unique: true)
            t.column(trackedPostsTitle)
            t.column(trackedPostsAge)
            t.column(trackedPostsRating)
            t.column(trackedPostsDomain)
            t.column(trackedPostsWasLoaded, defaultValue: false)
            t.column(trackedPostsViewID)
            t.column(trackedPostsEncounteredAt)
            t.column(trackedPostsLastAccessedAt)
            t.column(trackedPostsIsBookmarked, defaultValue: false)
        })
        logger.debug("tracked_posts table created successfully")
        
        logger.debug("Creating subscribed_blogs table")
        try connection.run(subscribedBlogs.create(ifNotExists: true) { t in
            t.column(subscribedBlogsID, primaryKey: .autoincrement)
            t.column(subscribedBlogsDomain, unique: true)
            t.column(subscribedBlogsFeedURL)
            t.column(subscribedBlogsTitle)
            t.column(subscribedBlogsSubscribedAt)
            t.column(subscribedBlogsLastFetchAt)
            t.column(subscribedBlogsNewPostsCount, defaultValue: 0)
        })
        logger.debug("subscribed_blogs table created successfully")
        
        logger.debug("Creating visit_history table")
        try connection.run(browsingHistoryTable.create(ifNotExists: true) { t in
            t.column(browsingHistoryID, primaryKey: .autoincrement)
            t.column(browsingHistoryURL)
            t.column(browsingHistoryTitle)
            t.column(browsingHistoryDate)
        })
        logger.debug("visit_history table created successfully")
        
        do {
            try connection.run(subscribedBlogs.addColumn(subscribedBlogsNewPostsCount, defaultValue: 0))
            logger.debug("Added newPostsCount column to existing table")
        } catch {
            logger.debug("newPostsCount column already exists")
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
            let trackedPost = TrackedPostData(
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
            results.append(trackedPost)
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
            let trackedPost = TrackedPostData(
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
            results.append(trackedPost)
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
            let trackedPost = TrackedPostData(
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
            results.append(trackedPost)
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
            let trackedPost = TrackedPostData(
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
            results.append(trackedPost)
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
                newPostsCount: row[subscribedBlogsNewPostsCount]
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
