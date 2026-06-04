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
    var translatedTitle: String?
    var translatedContent: PostContent?
    var isTranslated = false
    var isTranslating = false
    var translationErrorMessage: String?

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

    func translationRequests(forTitle title: String) -> [PostTranslationRequest] {
        guard let content else { return [] }

        var requests = [PostTranslationRequest(id: PostTranslationRequest.titleID, text: title)]
        requests.append(contentsOf: translationRequests(for: content.elements, prefix: "element"))
        return requests.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func applyTranslations(_ translations: [String: String]) {
        guard let content else { return }

        translatedTitle = translations[PostTranslationRequest.titleID]
        translatedContent = PostContent(elements: translatedElements(from: content.elements, translations: translations, prefix: "element"))
        isTranslated = true
        translationErrorMessage = nil
    }

    func showOriginalContent() {
        isTranslated = false
        translationErrorMessage = nil
    }

    func beginTranslation() {
        isTranslating = true
        translationErrorMessage = nil
    }

    func finishTranslation() {
        isTranslating = false
    }

    func failTranslation(_ error: Error) {
        isTranslating = false
        translationErrorMessage = ErrorHandler.message(for: error)
        HapticManager.error()
    }

    private func translationRequests(for elements: [ContentElement], prefix: String) -> [PostTranslationRequest] {
        elements.enumerated().flatMap { index, element -> [PostTranslationRequest] in
            let id = "\(prefix).\(index)"

            switch element {
            case .text(let attributedString):
                return [PostTranslationRequest(id: id, text: String(attributedString.characters))]
            case .header2(let text), .header3(let text):
                return [PostTranslationRequest(id: id, text: text)]
            case .tags(let tags):
                return tags.enumerated().map { tagIndex, tag in
                    PostTranslationRequest(id: "\(id).tag.\(tagIndex)", text: tag.text)
                }
            case .table(let table):
                var tableRequests: [PostTranslationRequest] = table.headers.enumerated().map { headerIndex, header in
                    PostTranslationRequest(id: "\(id).header.\(headerIndex)", text: header)
                }
                for (rowIndex, row) in table.rows.enumerated() {
                    tableRequests.append(contentsOf: row.enumerated().map { cellIndex, cell in
                        PostTranslationRequest(id: "\(id).row.\(rowIndex).cell.\(cellIndex)", text: cell)
                    })
                }
                return tableRequests
            case .blockquote(let elements):
                return translationRequests(for: elements, prefix: "\(id).blockquote")
            case .image, .codeBlock, .upvote, .video:
                return []
            }
        }
    }

    private func translatedElements(from elements: [ContentElement], translations: [String: String], prefix: String) -> [ContentElement] {
        elements.enumerated().map { index, element in
            let id = "\(prefix).\(index)"

            switch element {
            case .text(let attributedString):
                if let translatedText = translations[id] {
                    return .text(translatedAttributedString(from: attributedString, translatedText: translatedText))
                }
                return element
            case .header2(let text):
                return .header2(translations[id] ?? text)
            case .header3(let text):
                return .header3(translations[id] ?? text)
            case .tags(let tags):
                let translatedTags = tags.enumerated().map { tagIndex, tag in
                    PostTag(text: translations["\(id).tag.\(tagIndex)"] ?? tag.text, query: tag.query)
                }
                return .tags(translatedTags)
            case .table(let table):
                let translatedHeaders = table.headers.enumerated().map { headerIndex, header in
                    translations["\(id).header.\(headerIndex)"] ?? header
                }
                let translatedRows = table.rows.enumerated().map { rowIndex, row in
                    row.enumerated().map { cellIndex, cell in
                        translations["\(id).row.\(rowIndex).cell.\(cellIndex)"] ?? cell
                    }
                }
                return .table(PostTable(headers: translatedHeaders, rows: translatedRows))
            case .blockquote(let elements):
                return .blockquote(translatedElements(from: elements, translations: translations, prefix: "\(id).blockquote"))
            case .image, .codeBlock, .upvote, .video:
                return element
            }
        }
    }

    private func translatedAttributedString(from original: AttributedString, translatedText: String) -> AttributedString {
        let originalText = String(original.characters)
        let replacementText = translatedText.preservingBoundaryWhitespace(from: originalText)
        var translated = original
        translated.characters.replaceSubrange(
            translated.characters.startIndex..<translated.characters.endIndex,
            with: replacementText
        )
        return translated
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

private extension String {
    func preservingBoundaryWhitespace(from original: String) -> String {
        original.leadingWhitespace + trimmingCharacters(in: .whitespacesAndNewlines) + original.trailingWhitespace
    }

    private var leadingWhitespace: String {
        String(prefix { $0.isWhitespace })
    }

    private var trailingWhitespace: String {
        String(reversed().prefix { $0.isWhitespace }.reversed())
    }
}
