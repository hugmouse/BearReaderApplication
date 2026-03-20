//
//  DatabaseSchema.swift
//  BearReaderApplication
//

import Foundation
@unsafe @preconcurrency import SQLite

enum DatabaseSchema {

    // MARK: - tracked_posts

    static let trackedPosts = Table("tracked_posts")
    static let trackedPostsID = Expression<Int64>("id")
    static let trackedPostsURL = Expression<String>("url")
    static let trackedPostsTitle = Expression<String>("title")
    static let trackedPostsAge = Expression<String>("age")
    static let trackedPostsRating = Expression<String>("rating")
    static let trackedPostsDomain = Expression<String>("domain")
    static let trackedPostsWasLoaded = Expression<Bool>("was_loaded")
    static let trackedPostsViewID = Expression<Int>("view_id")
    static let trackedPostsEncounteredAt = Expression<Date>("encountered_at")
    static let trackedPostsLastAccessedAt = Expression<Date?>("last_accessed_at")
    static let trackedPostsIsBookmarked = Expression<Bool>("is_bookmarked")

    // MARK: - subscribed_blogs

    static let subscribedBlogs = Table("subscribed_blogs")
    static let subscribedBlogsID = Expression<Int64>("id")
    static let subscribedBlogsDomain = Expression<String>("domain")
    static let subscribedBlogsFeedURL = Expression<String>("feed_url")
    static let subscribedBlogsTitle = Expression<String>("blog_title")
    static let subscribedBlogsSubscribedAt = Expression<Date>("subscribed_at")
    static let subscribedBlogsLastFetchAt = Expression<Date?>("last_fetched_at")
    static let subscribedBlogsNewPostsCount = Expression<Int>("new_posts_count")
    static let subscribedBlogsIsNotificationsMuted = Expression<Bool>("is_notifications_muted")

    // MARK: - visit_history

    static let browsingHistoryTable = Table("visit_history")
    static let browsingHistoryID = Expression<Int64>("id")
    static let browsingHistoryURL = Expression<String>("url")
    static let browsingHistoryTitle = Expression<String>("title")
    static let browsingHistoryDate = Expression<Date>("date")
}
