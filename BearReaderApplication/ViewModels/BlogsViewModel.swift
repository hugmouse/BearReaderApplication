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
    @Published var showUndoToast = false
    @Published var recentlyDeletedBlog: BlogSubscription?

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
            recentlyDeletedBlog = blog
            showUndoToast = true
            
            try await DatabaseManager.shared.unsubscribeFromBlog(domain: blog.domain)
            await loadSubscribedBlogs()
            
            // Auto hide toast after 5 seconds using Task with cancellation support
            Task {
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                await MainActor.run {
                    if recentlyDeletedBlog?.domain == blog.domain {
                        withAnimation {
                            showUndoToast = false
                        }
                        // Clear the reference after animation completes
                        Task {
                            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s for animation
                            await MainActor.run {
                                if !showUndoToast {
                                    recentlyDeletedBlog = nil
                                }
                            }
                        }
                    }
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

        // Use concurrent requests instead of sequential loop
        await withTaskGroup(of: (String, Error?).self) { group in
            for blog in subscribedBlogs {
                group.addTask {
                    do {
                        _ = try await bearBlogService.getBlogFeed(domain: blog.domain)
                        try await DatabaseManager.shared.updateBlogLastFetched(domain: blog.domain)
                        return (blog.domain, nil)
                    } catch {
                        print("[warning] Failed to refresh blog \(blog.domain): \(error)")
                        return (blog.domain, error)
                    }
                }
            }
            
            // Collect results
            for await _ in group {
                // Results are already logged above
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
