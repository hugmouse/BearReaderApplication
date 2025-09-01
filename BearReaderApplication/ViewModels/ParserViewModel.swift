//
//  CSSSelectorViewModel.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import SwiftSoup

@MainActor
class ParserPreviewSelectorViewModel: ObservableObject {
    static let shared = ParserPreviewSelectorViewModel()
    
    @Published var isLoading = false
    @Published var cachedHTML: String?
    @Published var lastFetchURL: String?
    @Published var errorMessage: String?
    
    private let urlSession: URLSession
    private let maxPreviewElements = 5
    
    private init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": SettingsManager.shared.userAgent]
        self.urlSession = URLSession(configuration: config)
    }
    
    func fetchHTMLIfNeeded(from serviceURL: String) async {
        guard cachedHTML == nil || lastFetchURL != serviceURL else {
            return
        }
        
        await fetchHTML(from: serviceURL)
    }
    
    func fetchHTML(from serviceURL: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let url = URL(string: serviceURL) else {
                errorMessage = "Invalid service URL"
                isLoading = false
                return
            }
            
            let request = URLRequest(url: url)
            let (data, _) = try await urlSession.data(for: request)
            let html = String(data: data, encoding: .utf8) ?? ""
            
            cachedHTML = html
            lastFetchURL = serviceURL
            
        } catch {
            errorMessage = "Failed to fetch HTML: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshHTML() async {
        let currentURL = lastFetchURL ?? SettingsManager.shared.serviceURL
        cachedHTML = nil
        lastFetchURL = nil
        await fetchHTML(from: currentURL)
    }
    
    func previewSelector(_ selector: String) -> ParserPreviewResult {
        guard let html = cachedHTML else {
            return ParserPreviewResult(
                matchCount: 0,
                matchedElements: [],
                isValid: false,
                errorMessage: "No HTML cached. Please refresh preview."
            )
        }
        
        guard !selector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ParserPreviewResult(
                matchCount: 0,
                matchedElements: [],
                isValid: false,
                errorMessage: "Selector cannot be empty"
            )
        }
        
        do {
            let document = try SwiftSoup.parse(html)
            let elements = try document.select(selector)
            
            var matchedElements: [String] = []
            let count = elements.count
            
            for (index, element) in elements.enumerated() {
                if index >= maxPreviewElements { break }
                
                let tagName = element.tagName()
                let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                let displayText = text.isEmpty ? "<empty>" : text
                let preview = "\(tagName): \(displayText)"
                
                matchedElements.append(String(preview.prefix(100)))
            }
            
            return ParserPreviewResult(
                matchCount: count,
                matchedElements: matchedElements,
                isValid: true,
                errorMessage: nil
            )
            
        } catch {
            return ParserPreviewResult(
                matchCount: 0,
                matchedElements: [],
                isValid: false,
                errorMessage: "Invalid CSS selector: \(error.localizedDescription)"
            )
        }
    }
}
