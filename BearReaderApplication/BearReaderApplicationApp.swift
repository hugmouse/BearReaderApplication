//
//  BearReaderApplicationApp.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 01.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import BackgroundTasks
import os.log

@main
struct BearReaderApplicationApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.scenePhase) private var phase

    private let logger = Logger(subsystem: "BearReader", category: "BackgroundRefresh")
    private let backgroundTaskIdentifier = "com.bearreader.blogrefresh"

    init() {
        configureURLCache()
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .backgroundTask(.appRefresh(backgroundTaskIdentifier)) {
            await fetchBlogsData()
            Task { @MainActor in
                scheduleAppRefresh()
            }
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .background {
                scheduleAppRefresh()
            }
        }
    }

    private func configureURLCache() {
        let memoryCacheMB = UserDefaults.standard.object(forKey: "memoryCacheMB") as? Int ?? CacheSettings.defaults.memoryCacheMB
        let diskCacheMB = UserDefaults.standard.object(forKey: "diskCacheMB") as? Int ?? CacheSettings.defaults.diskCacheMB
        let memoryCapacity = memoryCacheMB * 1024 * 1024
        let diskCapacity = diskCacheMB * 1024 * 1024
        let urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
        URLCache.shared = urlCache
    }

    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = request.earliestBeginDate
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled next background refresh")
        } catch {
            logger.error("Could not schedule app refresh: \(error)")
        }
    }

    // TODO: move it out of here somewhere, don't think it belongs here
    private func fetchBlogsData() async {
        logger.info("Starting background blog refresh")

        do {
            let subscribedBlogs = try await DatabaseManager.shared.getSubscribedBlogs()
            logger.info("Found \(subscribedBlogs.count) subscribed blogs")

            let bearBlogService = BearBlogService()

            for blog in subscribedBlogs {
                do {
                    let existingPostsUrls = try await DatabaseManager.shared.getTrackedPostUrls(for: blog.domain)
                    let posts = try await bearBlogService.getBlogFeed(domain: blog.domain)

                    let newPosts = posts.filter { !existingPostsUrls.contains($0.url) }

                    if newPosts.count > 0 {
                        logger.info("Found \(newPosts.count) new posts for \(blog.domain)")
                        
                        if UIApplication.shared.applicationState == .background {
                            for newPost in newPosts {
                                let content = UNMutableNotificationContent()
                                content.title = "New post from \(blog.blogTitle)"
                                content.body = "\(newPost.title)"
                                content.sound = UNNotificationSound.default
                                content.threadIdentifier = blog.domain

                                
                                content.userInfo = [
                                    "title": newPost.title,
                                    "url": newPost.url,
                                    "age": newPost.age,
                                    "rating": newPost.rating,
                                    "domain": blog.domain
                                ]
                                
                                let request = UNNotificationRequest(identifier: newPost.url, content: content, trigger: nil)
                                do {
                                    try await UNUserNotificationCenter.current().add(request)
                                } catch {
                                    logger.error("Failed to add notification request upon recieving a new post from subscribed blog \(blog.domain): \(error.localizedDescription)")
                                }
                            }
                        }

                        try await DatabaseManager.shared.incrementNewPostsCount(domain: blog.domain, by: newPosts.count)
                    }

                    try await DatabaseManager.shared.updateBlogLastFetched(domain: blog.domain)
                } catch {
                    logger.error("Failed to refresh blog \(blog.domain): \(error.localizedDescription)")
                }
            }

            // I have no idea how can we track the fact that this actually triggered even once
            // without storing this fact somewhere in storage
            UserDefaults.standard.set(Date(), forKey: "lastBackgroundRefresh")
            logger.info("Background refresh completed")
        } catch {
            logger.error("Background refresh failed: \(error.localizedDescription)")
        }
    }
}
