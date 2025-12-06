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
    @Environment(\.scenePhase) private var phase

    private let logger = Logger(subsystem: "BearReader", category: "BackgroundRefresh")
    private let backgroundTaskIdentifier = "com.bearreader.blogrefresh"

    init() {
        configureURLCache()
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

    // TODO: make configurable by the user
    private func configureURLCache() {
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB
        let diskCapacity = 1000 * 1024 * 1024 // 1  GB
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
                            for (i, newPost) in newPosts.enumerated() {
                                let content = UNMutableNotificationContent()
                                content.title = "New post from \(blog.blogTitle)"
                                content.body = "\(newPost.title)"
                                content.sound = UNNotificationSound.default

                                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(5 + i), repeats: false)
                                let request = UNNotificationRequest(identifier: newPost.url, content: content, trigger: trigger)
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
