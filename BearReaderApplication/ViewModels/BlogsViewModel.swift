//
//  BlogsViewModel.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.10.25.
//
//  Copyright 2025 Iaroslav Angliuster
//

import Observation
import SwiftUI

@MainActor
@Observable class BlogsViewModel {
    var subscribedBlogs: [BlogSubscription] = []
    var isLoading = false
    var errorMessage: String?
    var showUndoToast = false
    var recentlyDeletedBlog: BlogSubscription?

    private let backgroundRefreshInterval: TimeInterval = AppConstants.backgroundRefreshInterval
    private let undoToastDuration: UInt64 = 5_000_000_000
    private let undoToastDismissBuffer: UInt64 = 500_000_000

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
            recentlyDeletedBlog = blog
            showUndoToast = true
            
            try await DatabaseManager.shared.unsubscribeFromBlog(domain: blog.domain)
            await loadSubscribedBlogs()
            
            // Auto hide toast after 5 seconds
            try? await Task.sleep(nanoseconds: undoToastDuration)
            if recentlyDeletedBlog?.domain == blog.domain {
                withAnimation {
                    showUndoToast = false
                }
                // Clear the reference after the toast is gone
                try? await Task.sleep(nanoseconds: undoToastDismissBuffer)
                if !showUndoToast {
                    recentlyDeletedBlog = nil
                }
            }
        } catch {
            errorMessage = "Failed to unsubscribe: \(error.localizedDescription)"
        }
    }

    func undoDelete() async {
        guard let blog = recentlyDeletedBlog else { return }
        
        do {
            try await DatabaseManager.shared.restoreBlog(blog)
            await loadSubscribedBlogs()
            withAnimation {
                showUndoToast = false
            }
            recentlyDeletedBlog = nil
        } catch {
            errorMessage = "Failed to restore blog: \(error.localizedDescription)"
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

    func markBlogAsViewed(domain: String) async {
        do {
            try await DatabaseManager.shared.resetNewPostsCount(domain: domain)
            await loadSubscribedBlogs()
        } catch {
            errorMessage = "Failed to update blog: \(error.localizedDescription)"
        }
    }

    func toggleNotificationsMuted(for blog: BlogSubscription) async {
        do {
            try await DatabaseManager.shared.toggleNotificationsMuted(domain: blog.domain)
            await loadSubscribedBlogs()
        } catch {
            errorMessage = "Failed to toggle notifications: \(error.localizedDescription)"
        }
    }
}
