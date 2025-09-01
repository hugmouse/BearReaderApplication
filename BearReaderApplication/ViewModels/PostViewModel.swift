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

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var content: PostContent?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoadingFromCache = false

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
