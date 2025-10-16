//
//  BlogsViewModel.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.10.25.
//
//  Copyright 2025 Iaroslav Angliuster
//

import Foundation
import SwiftUI

class BlogsViewModel: ObservableObject {
    @Published var subscribedBlogs: [BlogSubscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let backgroundRefreshInterval: TimeInterval = 3600

    func loadSubscribedBlogs() async {
        isLoading = true
        errorMessage = nil

        do {
            subscribedBlogs = try await DatabaseManager.shared.getSubscribedBlogs()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load subscribed blogs: \(error.localizedDescription)"
        }
    }

    func unsubscribe(from blog: BlogSubscription) async {
        do {
            try await DatabaseManager.shared.unsubscribeFromBlog(domain: blog.domain)
            await loadSubscribedBlogs()
        } catch {
            errorMessage = "Failed to unsubscribe: \(error.localizedDescription)"
        }
    }

    func refreshAllBlogs() async {
        isLoading = true
        errorMessage = nil

        let bearBlogService = BearBlogService()

        for blog in subscribedBlogs {
            do {
                _ = try await bearBlogService.getBlogFeed(domain: blog.domain)
                try await DatabaseManager.shared.updateBlogLastFetched(domain: blog.domain)
            } catch {
                print("[warning] Failed to refresh blog \(blog.domain): \(error)")
            }
        }

        // Reload the list to show updated timestamps
        await loadSubscribedBlogs()
        isLoading = false
    }

    func checkAndRefreshIfNeeded() async {
        if subscribedBlogs.contains(where: shouldRefreshBlog) {
            await refreshAllBlogs()
        }
    }

    private func shouldRefreshBlog(_ blog: BlogSubscription) -> Bool {
        guard let lastFetched = blog.lastFetchedAt else {
            return true // Never fetched, should refresh
        }
        let timeSinceLastFetch = Date().timeIntervalSince(lastFetched)
        return timeSinceLastFetch >= backgroundRefreshInterval
    }
}
