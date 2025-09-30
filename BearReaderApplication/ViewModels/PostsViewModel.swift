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

enum FeedType {
    case trending
    case recent
}

@MainActor
class PostsViewModel: ObservableObject {
    @Published var posts: [PostItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var isOffline = false
    @Published var isBlinking = false

    private let feedType: FeedType
    private let bearBlogService: BearBlogServiceProtocol
    private var currentPage = 1
    private var blinkTimer: Timer?
    
    init(feedType: FeedType, bearBlogService: BearBlogServiceProtocol = BearBlogService()) {
        self.feedType = feedType
        self.bearBlogService = bearBlogService
    }
    
    func loadInitialPosts(refresh: Bool = false) async {
        isLoading = true
        errorMessage = nil
        isOffline = false
        currentPage = 0

        do {
            let result = try await fetchPosts(page: currentPage, refresh: refresh)
            posts = result
            isLoading = false
        } catch {
            handleError(error, isInitialLoad: posts.isEmpty)
        }
    }
    
    func loadMorePosts() async {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        let nextPage = currentPage + 1
        
        do {
            let newPosts = try await fetchPosts(page: nextPage)
            self.posts.append(contentsOf: newPosts)
            self.currentPage = nextPage
        } catch {
            handleError(error, isInitialLoad: false)
        }
    }
    
    func shouldLoadMore(for post: PostItem) -> Bool {
        guard let index = posts.firstIndex(where: { $0.url == post.url }) else {
            return false
        }
        return index == posts.count - 10
    }

    func refresh() async {
        errorMessage = nil
        isOffline = false
        await loadInitialPosts(refresh: true)
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
