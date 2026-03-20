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
