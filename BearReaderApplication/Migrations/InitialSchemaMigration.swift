//
//  InitialSchemaMigration.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 20.01.26.
//

import Foundation
import SQLite
import SQLiteMigrationManager
import os.log

// This migration is a little bit weird since
// I had to add this on top of my previously DIY migration process
struct InitialSchemaMigration: Migration {
    var version: Int64 = 2026_01_20_16_45_04
    
    private let logger = Logger(subsystem: "BearReader", category: "InitialSchemaMigration")

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
    private let subscribedBlogsIsNotificationsMuted = Expression<Bool>("is_notifications_muted")
    
    private let browsingHistoryTable = Table("visit_history")
    private let browsingHistoryID = Expression<Int64>("id")
    private let browsingHistoryURL = Expression<String>("url")
    private let browsingHistoryTitle = Expression<String>("title")
    private let browsingHistoryDate = Expression<Date>("date")
    
    func migrateDatabase(_ db: Connection) throws {
        logger.debug("Starting initial schema migration")
        
        logger.debug("Creating tracked_posts table")
        try db.run(trackedPosts.create(ifNotExists: true) { t in
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
        logger.debug("tracked_posts table created successfully (or already existed)")
        
        logger.debug("Creating subscribed_blogs table")
        try db.run(subscribedBlogs.create(ifNotExists: true) { t in
            t.column(subscribedBlogsID, primaryKey: .autoincrement)
            t.column(subscribedBlogsDomain, unique: true)
            t.column(subscribedBlogsFeedURL)
            t.column(subscribedBlogsTitle)
            t.column(subscribedBlogsSubscribedAt)
            t.column(subscribedBlogsLastFetchAt)
            t.column(subscribedBlogsNewPostsCount, defaultValue: 0)
            t.column(subscribedBlogsIsNotificationsMuted, defaultValue: false)
        })
        logger.debug("subscribed_blogs table created successfully (or already existed)")
        
        logger.debug("Creating visit_history table")
        try db.run(browsingHistoryTable.create(ifNotExists: true) { t in
            t.column(browsingHistoryID, primaryKey: .autoincrement)
            t.column(browsingHistoryURL)
            t.column(browsingHistoryTitle)
            t.column(browsingHistoryDate)
        })
        logger.debug("visit_history table created successfully (or already existed)")
        
        do {
            try db.run(subscribedBlogs.addColumn(subscribedBlogsNewPostsCount, defaultValue: 0))
            logger.debug("Added newPostsCount column to existing table")
        } catch {
            logger.debug("newPostsCount column add failed (likely already exists)")
        }
        
        do {
            try db.run(subscribedBlogs.addColumn(subscribedBlogsIsNotificationsMuted, defaultValue: false))
            logger.debug("Added isNotificationsMuted column to existing table")
        } catch {
            logger.debug("isNotificationsMuted column add failed (likely already exists)")
        }
        
        logger.debug("Initial schema migration completed")
    }
}
