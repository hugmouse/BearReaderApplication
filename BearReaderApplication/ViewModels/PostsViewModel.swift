//
//  PostsViewModel.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import Foundation
import SwiftUI
import Observation

enum FeedType {
    case trending
    case recent
}

@MainActor
@Observable class PostsViewModel {
    var posts: [PostItem] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var isOffline = false

    private let feedType: FeedType
    private let bearBlogService: BearBlogServiceProtocol
    private var allPosts: [PostItem] = []
    private var currentPage = 0
    private var hasMorePages = true
    private var lastVisitedAt: Date?
    private var isStaleRefreshInProgress = false

    private static let staleRefreshInterval: TimeInterval = 10 * 60

    init(feedType: FeedType, bearBlogService: BearBlogServiceProtocol = BearBlogService()) {
        self.feedType = feedType
        self.bearBlogService = bearBlogService
    }

    func loadInitialPosts(refresh: Bool = false) async {
        isLoading = true
        errorMessage = nil
        isOffline = false
        currentPage = 0
        hasMorePages = true
        isStaleRefreshInProgress = false

        do {
            if refresh {
                do {
                    let result = try await fetchPosts(page: currentPage, refresh: true)
                    allPosts = result
                    applyTitleBlacklist()
                    hasMorePages = !result.isEmpty
                    isLoading = false
                    return
                } catch {
                    print("Refresh failed, falling back to cache if available. Error: \(error)")
                }
            }
            
            // Default load (uses cache if available from URLSession config)
            let result = try await fetchPosts(page: currentPage, refresh: false)
            allPosts = result
            applyTitleBlacklist()
            hasMorePages = !result.isEmpty
            isLoading = false
        } catch {
            handleError(error, isInitialLoad: posts.isEmpty)
        }
    }

    func refreshIfStaleAfterVisit() {
        let now = Date()
        let previousVisitAt = lastVisitedAt
        lastVisitedAt = now

        guard !allPosts.isEmpty else {
            guard !isLoading else { return }
            Task { await loadInitialPosts(refresh: feedType == .recent) }
            return
        }

        guard let previousVisitAt,
              now.timeIntervalSince(previousVisitAt) >= Self.staleRefreshInterval,
              !isLoading,
              !isLoadingMore,
              !isStaleRefreshInProgress
        else { return }

        Task { await refreshStalePosts() }
    }

    func loadMorePosts() async {
        guard !isLoadingMore && !isLoading && hasMorePages else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1

        do {
            let newPosts = try await fetchPosts(page: nextPage)

            if !newPosts.isEmpty {
                allPosts.append(contentsOf: newPosts)
                applyTitleBlacklist()
                currentPage = nextPage
            } else {
                hasMorePages = false
            }
        } catch {
            handleError(error, isInitialLoad: false)
        }
    }

    func shouldLoadMore(currentItem item: PostItem?) -> Bool {
        guard !isLoadingMore && !isLoading && hasMorePages else { return false }
        guard let item = item else { return false }

        guard let itemIndex = posts.firstIndex(where: { $0.id == item.id }) else {
            return false
        }

        guard posts.count >= 5 else { return false }
        let thresholdIndex = posts.index(posts.endIndex, offsetBy: -5)
        return itemIndex >= thresholdIndex
    }
    
    func refresh() async {
        errorMessage = nil
        isOffline = false
        await loadInitialPosts(refresh: true)
    }

    func applyTitleBlacklist() {
        let blacklistTerms = SettingsManager.shared.titleBlacklistTerms
        guard !blacklistTerms.isEmpty else {
            posts = allPosts
            return
        }

        posts = allPosts.filter { post in
            !blacklistTerms.contains { term in
                post.title.localizedCaseInsensitiveContains(term)
            }
        }
    }

    private func refreshStalePosts() async {
        isStaleRefreshInProgress = true
        defer { isStaleRefreshInProgress = false }

        do {
            let refreshedPosts = try await fetchPosts(page: 0, refresh: true)
            guard !refreshedPosts.isEmpty else { return }
            allPosts = refreshedPosts
            applyTitleBlacklist()
            currentPage = 0
            hasMorePages = true
            errorMessage = nil
            isOffline = false
        } catch {
            handleError(error, isInitialLoad: false)
        }
    }
    
    private func fetchPosts(page: Int, refresh: Bool = false) async throws -> [PostItem] {
        switch feedType {
        case .trending:
            return try await bearBlogService.getTrending(page: page, language: nil, refresh: refresh)
        case .recent:
            return try await bearBlogService.getRecent(page: page, language: nil, refresh: refresh)
        }
    }
    
    private func handleError(_ error: Error, isInitialLoad: Bool = false) {
        isLoading = false
        isLoadingMore = false
        
        let isNetworkError = NetworkMonitor.isNetworkError(error)
        isOffline = isNetworkError
        
        if isNetworkError && !isInitialLoad && !posts.isEmpty {
            errorMessage = "No internet connection. Showing cached posts."
        } else if isNetworkError && posts.isEmpty {
            errorMessage = "No internet connection. Check your network or browse previously read posts in Profile → History or Profile → Bookmarks."
        } else {
            errorMessage = ErrorHandler.message(for: error)
        }
    }
}

struct ErrorHandler {
    static func message(for error: Error) -> String {
        if let bearBlogError = error as? BearBlogError {
            switch bearBlogError {
            case .invalidURL:
                return "Invalid URL"
            case .noData:
                return "No data received"
            case .networkError(let networkError):
                return "Network error: \(networkError.localizedDescription)"
            case .parsingError(let parsingError):
                return "Parsing error: \(parsingError.localizedDescription)"
            }
        } else {
            return error.localizedDescription
        }
    }
}
