//
//  BlogFeedViewModel.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.10.25.
//
//  Copyright 2025 Iaroslav Angliuster
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable class BlogFeedViewModel {
    var posts: [PostItem] = []
    var isLoading = false
    var errorMessage: String?
    var isOffline = false

    private let domain: String
    private let bearBlogService: BearBlogServiceProtocol

    init(domain: String, bearBlogService: BearBlogServiceProtocol = BearBlogService()) {
        self.domain = domain
        self.bearBlogService = bearBlogService
    }

    func loadFeed(refresh: Bool = false, updateLastFetched: Bool = true) async {
        isLoading = true
        errorMessage = nil
        isOffline = false

        do {
            let feedPosts = try await bearBlogService.getBlogFeed(domain: domain)
            posts = feedPosts

            if updateLastFetched {
                try await DatabaseManager.shared.updateBlogLastFetched(domain: domain)
            }

            isLoading = false
        } catch {
            handleError(error)
        }
    }

    func refresh(updateLastFetched: Bool = true) async {
        await loadFeed(refresh: true, updateLastFetched: updateLastFetched)
    }

    func markAsRead() async {
        do {
            try await DatabaseManager.shared.resetNewPostsCount(domain: domain)
        } catch {
            print("Failed to mark blog as read: \(error)")
        }
    }

    private func handleError(_ error: Error) {
        isLoading = false

        let isNetworkError = NetworkMonitor.isNetworkError(error)
        isOffline = isNetworkError

        if isNetworkError {
            errorMessage = "No internet connection. Unable to load blog feed."
        } else {
            errorMessage = ErrorHandler.message(for: error)
        }
    }
}
