//
//  PostViewModel.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import Foundation
import SwiftUI
import Observation
import os.log

@MainActor
@Observable class PostDetailViewModel {
    var content: PostContent?
    var isLoading = false
    var errorMessage: String?
    var isLoadingFromCache = false
    var isBookmarked = false
    var isSubscribed = false

    private let logger = Logger(subsystem: "BearReader", category: "PostDetailViewModel")

    /// Offset for header elements (title, metadata, spacing) in the scroll target layout
    private let scrollRestorationHeaderOffset = 3

    private let bearBlogService: BearBlogServiceProtocol
    
    init(bearBlogService: BearBlogServiceProtocol = BearBlogService()) {
        self.bearBlogService = bearBlogService
    }
    
    func loadContent(from urlPath: String) async {
        guard content == nil else { return } // Don't reload if content is already loaded

        isLoading = true
        errorMessage = nil
        isLoadingFromCache = checkIfCached(urlPath: urlPath)

        do {
            let postContent = try await bearBlogService.getPostContent(from: urlPath)
            content = postContent
            isLoading = false
            isLoadingFromCache = false
            try await DatabaseManager.shared.markAsLoaded(urlPath)
        } catch {
            handleError(error)
        }
    }

    func loadPostStatus(url: String, title: String, domain: String) async {
        do {
            let status = try await DatabaseManager.shared.getPostStatusAndRecordHistory(
                postUrl: url,
                postTitle: title,
                blogDomain: domain
            )
            isBookmarked = status.isBookmarked
            isSubscribed = status.isSubscribed
        } catch {
            logger.error("Failed to load post status: \(error.localizedDescription)")
            isBookmarked = false
            isSubscribed = false
        }
    }

    func restoreScrollPosition(url: String) async -> Int? {
        do {
            guard let storedViewID = try await DatabaseManager.shared.getViewID(url) else {
                return nil
            }
            return storedViewID + scrollRestorationHeaderOffset
        } catch {
            logger.debug("Failed to restore scroll position: \(error.localizedDescription)")
            return nil
        }
    }

    func updateScrollPosition(url: String, viewID: Int) async {
        do {
            try await DatabaseManager.shared.updateViewID(url, viewID: viewID)
        } catch {
            logger.debug("Failed to save scroll position: \(error.localizedDescription)")
        }
    }

    func toggleBookmark(url: String) async {
        do {
            try await DatabaseManager.shared.toggleBookmark(url)
            isBookmarked.toggle()
            HapticManager.success()
        } catch {
            logger.error("Failed to toggle bookmark: \(error.localizedDescription)")
            HapticManager.error()
        }
    }

    func toggleSubscription(domain: String, currentlySubscribed: Bool) async {
        do {
            if currentlySubscribed {
                try await DatabaseManager.shared.unsubscribeFromBlog(domain: domain)
                isSubscribed = false
            } else {
                let blogTitle = domain.components(separatedBy: ".").first?.capitalized ?? domain
                let blogUrl = "https://\(domain)/blog/"
                try await DatabaseManager.shared.subscribeToBlog(domain: domain, feedUrl: blogUrl, blogTitle: blogTitle)
                isSubscribed = true
            }
            HapticManager.success()
        } catch {
            logger.error("Failed to toggle subscription: \(error.localizedDescription)")
            HapticManager.error()
        }
    }

    private func checkIfCached(urlPath: String) -> Bool {
        guard let url = URL(string: urlPath.hasPrefix("//") ? "https:" + urlPath : urlPath) else {
            return false
        }

        let request = URLRequest(url: url)
        return URLCache.shared.cachedResponse(for: request) != nil
    }
    
    private func handleError(_ error: Error) {
        isLoading = false
        isLoadingFromCache = false
        errorMessage = ErrorHandler.message(for: error)
    }
}
