//
//  AddPerformanceIndexesMigration.swift
//  BearReaderApplication
//
//  Created by Performance Optimization on 14.02.26.
//

import Foundation
import SQLite
import SQLiteMigrationManager
import os.log

struct AddPerformanceIndexesMigration: Migration {
    var version: Int64 = 2026_02_14_16_30_00
    
    private let logger = Logger(subsystem: "BearReader", category: "AddPerformanceIndexesMigration")
    
    func migrateDatabase(_ db: Connection) throws {
        logger.debug("Starting performance indexes migration")
        
        // Add index on tracked_posts.url for faster lookups
        logger.debug("Creating index on tracked_posts.url")
        try db.run("CREATE INDEX IF NOT EXISTS idx_tracked_posts_url ON tracked_posts(url)")
        
        // Add index on tracked_posts.domain for faster filtering by domain
        logger.debug("Creating index on tracked_posts.domain")
        try db.run("CREATE INDEX IF NOT EXISTS idx_tracked_posts_domain ON tracked_posts(domain)")
        
        // Add index on tracked_posts.title for faster search queries
        logger.debug("Creating index on tracked_posts.title")
        try db.run("CREATE INDEX IF NOT EXISTS idx_tracked_posts_title ON tracked_posts(title)")
        
        // Add index on tracked_posts.last_accessed_at for faster sorting
        logger.debug("Creating index on tracked_posts.last_accessed_at")
        try db.run("CREATE INDEX IF NOT EXISTS idx_tracked_posts_last_accessed ON tracked_posts(last_accessed_at)")
        
        // Add index on tracked_posts.is_bookmarked for faster bookmark queries
        logger.debug("Creating index on tracked_posts.is_bookmarked")
        try db.run("CREATE INDEX IF NOT EXISTS idx_tracked_posts_bookmarked ON tracked_posts(is_bookmarked)")
        
        // Add index on tracked_posts.view_id for faster read posts queries
        logger.debug("Creating index on tracked_posts.view_id")
        try db.run("CREATE INDEX IF NOT EXISTS idx_tracked_posts_view_id ON tracked_posts(view_id)")
        
        // Add index on subscribed_blogs.domain for faster lookups
        logger.debug("Creating index on subscribed_blogs.domain")
        try db.run("CREATE INDEX IF NOT EXISTS idx_subscribed_blogs_domain ON subscribed_blogs(domain)")
        
        // Add index on visit_history.date for faster sorting
        logger.debug("Creating index on visit_history.date")
        try db.run("CREATE INDEX IF NOT EXISTS idx_visit_history_date ON visit_history(date)")
        
        logger.debug("Performance indexes migration completed")
    }
}
