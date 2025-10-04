//
//  BearBlogAPI.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import Foundation
import SwiftSoup

enum BearBlogError: Error {
    case invalidURL
    case noData
    case networkError(Error)
    case parsingError(Error)
}

protocol BearBlogServiceProtocol {
    func getTrending(page: Int, language: String?, refresh: Bool) async throws -> [PostItem]
    func getRecent(page: Int, language: String?, refresh: Bool) async throws -> [PostItem]
    func getPostContent(from urlPath: String) async throws -> PostContent
    func getBlogFeed(domain: String) async throws -> [PostItem]
}

final class BearBlogService: BearBlogServiceProtocol, Sendable {
    private let urlSession: URLSession
    private let settingsProvider: SendableSettingsProvider
    private let customSettings: SettingsModel?

    init(urlSession: URLSession? = nil, settings: SettingsModel? = nil, settingsProvider: SendableSettingsProvider = .shared) {
        self.customSettings = settings
        self.settingsProvider = settingsProvider

        if let urlSession = urlSession {
            self.urlSession = urlSession
        } else {
            let config = URLSessionConfiguration.default
            let userAgent = settings?.userAgent ?? SettingsHelper.getDefaultSettings().userAgent
            config.httpAdditionalHeaders = ["User-Agent": userAgent]
            config.requestCachePolicy = .returnCacheDataElseLoad
            config.urlCache = URLCache.shared
            self.urlSession = URLSession(configuration: config)
        }
    }

    private func getCurrentSettings() async -> SettingsModel {
        if let customSettings = customSettings {
            return customSettings
        }
        return await settingsProvider.getCurrentSettings()
    }
    
    func getTrending(page: Int = 0, language: String? = nil, refresh: Bool = false) async throws -> [PostItem] {
        let settings = await getCurrentSettings()
        let baseURL = settings.serviceURL.hasSuffix("/")
        ? String(settings.serviceURL.dropLast())
        : settings.serviceURL
        guard let url = URL(string: "\(baseURL)?page=\(page)") else {
            throw BearBlogError.invalidURL
        }
                
        var request = URLRequest(url: url)
        
        if refresh {
            request.cachePolicy = .useProtocolCachePolicy
        }
        
        if let language = language {
            request.setValue("lang=\(language);", forHTTPHeaderField: "Cookie")
        }
        
        do {
            let (data, _) = try await self.urlSession.data(for: request)
            let html = String(data: data, encoding: .utf8) ?? ""
            return try await getPosts(from: html)
        } catch {
            throw BearBlogError.networkError(error)
        }
    }
    
    func getRecent(page: Int = 1, language: String? = nil, refresh: Bool = false) async throws -> [PostItem] {
        let settings = await getCurrentSettings()
        let baseURL = settings.serviceURL.hasSuffix("/")
        ? String(settings.serviceURL.dropLast())
        : settings.serviceURL
        guard let url = URL(string: "\(baseURL)?newest=true&page=\(page)") else {
            throw BearBlogError.invalidURL
        }
        
        
        var request = URLRequest(url: url)
        
        if refresh {
            request.cachePolicy = .useProtocolCachePolicy
        }
        
        if let language = language {
            request.setValue("lang=\(language);", forHTTPHeaderField: "Cookie")
        }
        
        do {
            let (data, _) = try await self.urlSession.data(for: request)
            let html = String(data: data, encoding: .utf8) ?? ""
            return try await getPosts(from: html)
        } catch {
            throw BearBlogError.networkError(error)
        }
    }
    
    func getPostContent(from urlPath: String) async throws -> PostContent {
        var fullURL = urlPath
        if urlPath.hasPrefix("//") {
            fullURL = "https:" + urlPath
        }
        
        guard let url = URL(string: fullURL) else {
            throw BearBlogError.invalidURL
        }
        
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            let (data, _) = try await self.urlSession.data(for: request)
            let html = String(data: data, encoding: .utf8) ?? ""
            
            guard let postContent = try await parseMainContentToStructured(from: html) else {
                throw BearBlogError.noData
            }
            
            return postContent
        } catch {
            if error is BearBlogError {
                throw error
            } else {
                throw BearBlogError.networkError(error)
            }
        }
    }
    
    func getPosts(from html: String) async throws -> [PostItem] {
        let settings = await getCurrentSettings()
        let document = try parse(html)
        let posts = try document.select(settings.cssSelectors.postsList)
        
        var _posts = [PostItem]()
        for post in posts {
            let title = try post.select(settings.cssSelectors.postTitle).text()
            let url = try post.select(settings.cssSelectors.postTitle).attr("href")
            let age = try post.select(settings.cssSelectors.postAge).text()
            let rating = try post.select(settings.cssSelectors.postRating).text()
            try await DatabaseManager.shared.saveEncounteredPost(PostItem(title: title, url: url, age: age, rating: rating))
            _posts.append(PostItem(title: title, url: url, age: age, rating: rating))
        }
        
        return _posts
    }
    
    private func parseMainContentToStructured(from html: String) async throws -> PostContent? {
        let settings = await getCurrentSettings()
        let document = try parse(html)

        // No <main> - no gain
        guard let mainElement = try document.select(settings.cssSelectors.mainContent).first() else {
            return nil
        }

        var elements: [ContentElement] = []
        try await parseElements(from: mainElement, into: &elements, settings: settings)

        return PostContent(elements: elements)
    }

    private func parseElements(from container: Element, into elements: inout [ContentElement], settings: SettingsModel) async throws {
        let children = try container.select("> *")

        for child in children {
            let tagName = child.tagName()

            switch tagName {
            case "img":
                // In this case, we actually need to add padding at the bottom since we are not in <p>
                if let images = try? child.select("img").compactMap({ img in
                    let src = try? img.attr("src")
                    let alt = try? img.attr("alt")
                    return (src != nil && !src!.isEmpty) ? PostImage(url: src!, altText: alt ?? "", needsPadding: true) : nil
                }) {
                    images.forEach { elements.append(.image($0)) }
                }

            case "p", "a":
                // Check if this is a tags paragraph
                if let classAttr = try? child.attr("class"), classAttr == "tags" {
                    let tagLinks = try child.select("a")
                    let tags = tagLinks.compactMap { link -> PostTag? in
                        guard let href = try? link.attr("href"),
                              let text = try? link.text(),
                              text.hasPrefix("#") else { return nil }

                        // Extract query parameter from href like "/blog/?q=ai"
                        let components = href.components(separatedBy: "?q=")
                        let query = components.count > 1 ? components[1] : ""

                        return PostTag(text: text, query: query)
                    }

                    if !tags.isEmpty {
                        elements.append(.tags(tags))
                    }
                } else {
                    // Usually img is hidden within <p>, sometimes <a>
                    if let images = try? child.select("img").compactMap({ img in
                        let src = try? img.attr("src")
                        let alt = try? img.attr("alt")
                        return (src != nil && !src!.isEmpty) ? PostImage(url: src!, altText: alt ?? "", needsPadding: false) : nil
                    }) {
                        images.forEach { elements.append(.image($0)) }
                    }

                    // Remove image elements before parsing the text content of the paragraph,
                    // otherwise attributedstring actually tries to display it
                    try child.select("img").remove()
                    let htmlContent = try child.outerHtml()
                    if !htmlContent.isEmpty, let attributedText = try? HTMLProcessor.htmlToAttributedString(html: htmlContent) {
                        elements.append(.text(attributedText))
                    }
                }
            case "iframe":
                if let src = try? child.attr("src") {
                    switch src {
                    case let url where url.contains("youtube.com/embed") || url.contains("youtube-nocookie.com/embed/"):
                        let title = (try? child.attr("title")) ?? "Video"
                        let platform = "YouTube"
                        
                        let videoId = url.components(separatedBy: "/").last?.components(separatedBy: "?").first ?? ""
                        let thumbnailUrl = "https://img.youtube.com/vi/\(videoId)/maxresdefault.jpg"
                        
                        let video = PostVideo(
                            embedUrl: url,
                            thumbnailUrl: thumbnailUrl,
                            title: title,
                            platform: platform
                        )
                        elements.append(.video(video))
                        continue
                        
                    case let url where url.contains("vimeo.com"):
                        let title = (try? child.attr("title")) ?? "Video"
                        let platform = "Vimeo"
                        // TODO: Support Vimeo thumbnail fetching, requires API call (public though)
                        let thumbnailUrl = ""
                        
                        let video = PostVideo(
                            embedUrl: url,
                            thumbnailUrl: thumbnailUrl,
                            title: title,
                            platform: platform
                        )
                        elements.append(.video(video))
                        continue
                        
                    default:
                        print("Encountered unsupported iframe", child)
                    }
                }
            case "pre":
                if let preText = try? child.text(), !preText.isEmpty {
                    elements.append(.codeBlock(preText))
                    continue
                }
            case "div":
                // Generic div - recursively parse its children
                try await parseElements(from: child, into: &elements, settings: settings)

            case "h1": continue
            case "h2":
                let text = try child.text()
                if !text.isEmpty {
                    elements.append(.header2(text))
                }
            case "h3":
                let text = try child.text()
                if !text.isEmpty {
                    elements.append(.header3(text))
                }
            case "form":
                if let formId = try? child.attr("id"), formId == "upvote-form",
                   let uidInput = try? child.select("input[name='uid']").first(),
                   let uid = try? uidInput.attr("value"),
                   let titleInput = try? child.select("input[name='title']").first(),
                   let title = try? titleInput.attr("value"),
                   let countElement = try? child.select(".upvote-count").first(),
                   let countText = try? countElement.text(),
                   let count = Int(countText) {
                    let upvote = PostUpvote(uid: uid, title: title, count: count)
                    elements.append(.upvote(upvote))
                }
            default:
                let htmlContent = try child.outerHtml()
                if !htmlContent.isEmpty, let attributedText = try? HTMLProcessor.htmlToAttributedString(html: htmlContent) {
                    elements.append(.text(attributedText))
                }
            }
        }
    }

    // I truly hope that they will never change URL, otherwise this will completely destroy itself
    func getBlogFeed(domain: String) async throws -> [PostItem] {
        var blogURL = domain
        if !blogURL.hasPrefix("http://") && !blogURL.hasPrefix("https://") {
            blogURL = "https://" + blogURL
        }
        if blogURL.hasSuffix("/") {
            blogURL = String(blogURL.dropLast())
        }
        blogURL = blogURL + "/blog/"

        guard let url = URL(string: blogURL) else {
            throw BearBlogError.invalidURL
        }

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            let (data, _) = try await self.urlSession.data(for: request)
            let html = String(data: data, encoding: .utf8) ?? ""

            // Parse blog posts from HTML
            return try await parseBlogPosts(from: html, baseURL: blogURL)
        } catch {
            if error is BearBlogError {
                throw error
            } else {
                throw BearBlogError.networkError(error)
            }
        }
    }

    private func parseBlogPosts(from html: String, baseURL: String) async throws -> [PostItem] {
        let document = try parse(html)
        let postListItems = try document.select("ul.blog-posts li")

        var posts: [PostItem] = []

        for listItem in postListItems {
            let timeElement = try listItem.select("span i time").first()
            let dateString = try timeElement?.text() ?? ""

            let linkElement = try listItem.select("a").first()
            guard let title = try linkElement?.text(),
                  let href = try linkElement?.attr("href") else {
                continue
            }


            let fullURL: String
            if href.hasPrefix("http://") || href.hasPrefix("https://") {
                fullURL = href
            } else if href.hasPrefix("/") {
                if let baseURLObj = URL(string: baseURL),
                   let scheme = baseURLObj.scheme,
                   let host = baseURLObj.host {
                    fullURL = "\(scheme)://\(host)\(href)"
                } else {
                    fullURL = baseURL.replacingOccurrences(of: "/blog/", with: "") + href
                }
            } else {
                fullURL = baseURL + href
            }

            let post = PostItem(
                title: title,
                url: fullURL,
                age: dateString,
                rating: "—"
            )
            posts.append(post)
        }

        return posts
    }
}
