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
    private let id = Expression<Int64>("id")
    private let url = Expression<String>("url")
    private let title = Expression<String>("title")
    private let age = Expression<String>("age")
    private let rating = Expression<String>("rating")
    private let domain = Expression<String>("domain")
    private let wasLoaded = Expression<Bool>("was_loaded")
    private let viewID = Expression<Int>("view_id")
    private let encounteredAt = Expression<Date>("encountered_at")
    private let lastAccessedAt = Expression<Date?>("last_accessed_at")
    private let isBookmarked = Expression<Bool>("is_bookmarked")

    private let subscribedBlogs = Table("subscribed_blogs")
    private let blogId = Expression<Int64>("id")
    private let blogDomain = Expression<String>("domain")
    private let blogFeedUrl = Expression<String>("feed_url")
    private let blogTitle = Expression<String>("blog_title")
    private let subscribedAt = Expression<Date>("subscribed_at")
    private let lastFetchedAt = Expression<Date?>("last_fetched_at")

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
    
    private func createTable(using connection: Connection) throws {
        logger.debug("Creating tracked_posts table")
        try connection.run(trackedPosts.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(url, unique: true)
            t.column(title)
            t.column(age)
            t.column(rating)
            t.column(domain)
            t.column(wasLoaded, defaultValue: false)
            t.column(viewID)
            t.column(encounteredAt)
            t.column(lastAccessedAt)
            t.column(isBookmarked, defaultValue: false)
        })
        logger.debug("tracked_posts table created successfully")

        logger.debug("Creating subscribed_blogs table")
        try connection.run(subscribedBlogs.create(ifNotExists: true) { t in
            t.column(blogId, primaryKey: .autoincrement)
            t.column(blogDomain, unique: true)
            t.column(blogFeedUrl)
            t.column(blogTitle)
            t.column(subscribedAt)
            t.column(lastFetchedAt)
        })
        logger.debug("subscribed_blogs table created successfully")
    }
    
    
    func saveEncounteredPost(_ post: PostItem) throws {
        let conn = try connection
        logger.debug("Saving encountered post: \(post.title) at \(post.url)")
        let insert = trackedPosts.insert(or: .ignore,
                                         url <- post.url,
                                         title <- post.title,
                                         age <- post.age,
                                         rating <- post.rating,
                                         domain <- post.domain,
                                         encounteredAt <- Date(),
                                         viewID <- 0,
        )
        try conn.run(insert)
        logger.debug("Post saved successfully: \(post.url)")
    }
    
    func markAsLoaded(_ postUrl: String) throws {
        let conn = try connection
        logger.debug("Marking post as loaded: \(postUrl)")
        let post = trackedPosts.filter(url == postUrl)
        try conn.run(post.update(
            wasLoaded <- true,
            lastAccessedAt <- Date()
        ))
        logger.debug("Post marked as loaded: \(postUrl)")
    }
    
    func updateViewID(_ postUrl: String, viewID: Int) throws {
        let conn = try connection
        logger.debug("Updating view ID for \(postUrl): \(viewID)")
        let post = trackedPosts.filter(url == postUrl)
        try conn.run(post.update(
            self.viewID <- viewID,
            lastAccessedAt <- Date()
        ))
        logger.debug("View ID updated for \(postUrl)")
    }
    
    
    func getViewID(_ postUrl: String) throws -> Int? {
        let conn = try connection
        logger.debug("Getting view ID for: \(postUrl)")
        let query = trackedPosts.filter(url == postUrl).limit(1)
        for row in try conn.prepare(query) {
            let id = row[viewID]
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
        let searchQuery = trackedPosts.filter(title.like("%\(query)%") || domain.like("%\(query)%"))
            .order(lastAccessedAt.desc)

        for row in try conn.prepare(searchQuery) {
            let trackedPost = TrackedPostData(
                id: row[id],
                url: row[url],
                title: row[title],
                age: row[age],
                rating: row[rating],
                domain: row[domain],
                wasLoaded: row[wasLoaded],
                viewID: row[viewID],
                encounteredAt: row[encounteredAt],
                lastAccessedAt: row[lastAccessedAt],
                isBookmarked: row[isBookmarked]
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
        let query = trackedPosts.filter(viewID > 0).order(lastAccessedAt.desc)

        for row in try conn.prepare(query) {
            let trackedPost = TrackedPostData(
                id: row[id],
                url: row[url],
                title: row[title],
                age: row[age],
                rating: row[rating],
                domain: row[domain],
                wasLoaded: row[wasLoaded],
                viewID: row[viewID],
                encounteredAt: row[encounteredAt],
                lastAccessedAt: row[lastAccessedAt],
                isBookmarked: row[isBookmarked]
            )
            results.append(trackedPost)
        }
        logger.debug("Retrieved \(results.count) read posts")

        return results
    }
    
    func removeTrackedPost(_ postUrl: String) throws {
        let conn = try connection
        logger.debug("Removing tracked post: \(postUrl)")
        let post = trackedPosts.filter(url == postUrl)
        try conn.run(post.delete())
        logger.debug("Tracked post removed: \(postUrl)")
    }
    
    func getAllTrackedPosts() throws -> [TrackedPostData] {
        let conn = try connection
        var results: [TrackedPostData] = []

        logger.debug("Fetching all tracked posts")
        let query = trackedPosts.order(encounteredAt.desc)

        for row in try conn.prepare(query) {
            let trackedPost = TrackedPostData(
                id: row[id],
                url: row[url],
                title: row[title],
                age: row[age],
                rating: row[rating],
                domain: row[domain],
                wasLoaded: row[wasLoaded],
                viewID: row[viewID],
                encounteredAt: row[encounteredAt],
                lastAccessedAt: row[lastAccessedAt],
                isBookmarked: row[isBookmarked]
            )
            results.append(trackedPost)
        }
        logger.debug("Retrieved \(results.count) total tracked posts")

        return results
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

        let post = trackedPosts.filter(url == postUrl)
        let currentBookmarkStatus = try conn.pluck(post.select(isBookmarked))
        let newBookmarkStatus = !(currentBookmarkStatus?[isBookmarked] ?? false)

        try conn.run(post.update(isBookmarked <- newBookmarkStatus))
        logger.debug("Bookmark toggled for \(postUrl): \(newBookmarkStatus)")
    }

    func isPostBookmarked(_ postUrl: String) throws -> Bool {
        let conn = try connection
        logger.debug("Checking bookmark status for: \(postUrl)")

        let post = trackedPosts.filter(url == postUrl)
        if let row = try conn.pluck(post.select(isBookmarked)) {
            return row[isBookmarked]
        }
        return false
    }

    func getBookmarkedPosts() throws -> [TrackedPostData] {
        let conn = try connection
        var results: [TrackedPostData] = []

        logger.debug("Fetching bookmarked posts")
        let query = trackedPosts.filter(isBookmarked == true).order(lastAccessedAt.desc)

        for row in try conn.prepare(query) {
            let trackedPost = TrackedPostData(
                id: row[id],
                url: row[url],
                title: row[title],
                age: row[age],
                rating: row[rating],
                domain: row[domain],
                wasLoaded: row[wasLoaded],
                viewID: row[viewID],
                encounteredAt: row[encounteredAt],
                lastAccessedAt: row[lastAccessedAt],
                isBookmarked: row[isBookmarked]
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
                                           blogDomain <- domain,
                                           blogFeedUrl <- feedUrl,
                                           blogTitle <- titleValue,
                                           subscribedAt <- Date(),
                                           lastFetchedAt <- nil
        )
        try conn.run(insert)
        logger.debug("Subscribed to blog: \(domain)")
    }

    func unsubscribeFromBlog(domain: String) throws {
        let conn = try connection
        logger.debug("Unsubscribing from blog: \(domain)")
        let blog = subscribedBlogs.filter(blogDomain == domain)
        try conn.run(blog.delete())
        logger.debug("Unsubscribed from blog: \(domain)")
    }

    func isSubscribedToBlog(domain: String) throws -> Bool {
        let conn = try connection
        logger.debug("Checking subscription status for: \(domain)")
        let query = subscribedBlogs.filter(blogDomain == domain).limit(1)
        let count = try conn.scalar(query.count)
        logger.debug("Subscription status for \(domain): \(count > 0)")
        return count > 0
    }

    func getSubscribedBlogs() throws -> [BlogSubscription] {
        let conn = try connection
        var results: [BlogSubscription] = []

        logger.debug("Fetching subscribed blogs")
        let query = subscribedBlogs.order(subscribedAt.desc)

        for row in try conn.prepare(query) {
            let subscription = BlogSubscription(
                id: row[blogId],
                domain: row[blogDomain],
                feedUrl: row[blogFeedUrl],
                blogTitle: row[blogTitle],
                subscribedAt: row[subscribedAt],
                lastFetchedAt: row[lastFetchedAt]
            )
            results.append(subscription)
        }
        logger.debug("Retrieved \(results.count) subscribed blogs")

        return results
    }

    func updateBlogLastFetched(domain: String) throws {
        let conn = try connection
        logger.debug("Updating last fetched time for blog: \(domain)")
        let blog = subscribedBlogs.filter(blogDomain == domain)
        try conn.run(blog.update(lastFetchedAt <- Date()))
        logger.debug("Updated last fetched time for blog: \(domain)")
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
