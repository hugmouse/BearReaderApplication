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

@MainActor
class BlogFeedViewModel: ObservableObject {
    @Published var posts: [PostItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOffline = false

    private let domain: String
    private let bearBlogService: BearBlogServiceProtocol

    init(domain: String, bearBlogService: BearBlogServiceProtocol = BearBlogService()) {
        self.domain = domain
        self.bearBlogService = bearBlogService
    }

    func loadFeed(refresh: Bool = false) async {
        isLoading = true
        errorMessage = nil
        isOffline = false

        do {
            let feedPosts = try await bearBlogService.getBlogFeed(domain: domain)
            posts = feedPosts

            // Update last fetched timestamp
            try await DatabaseManager.shared.updateBlogLastFetched(domain: domain)

            isLoading = false
        } catch {
            handleError(error)
        }
    }

    func refresh() async {
        await loadFeed(refresh: true)
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
