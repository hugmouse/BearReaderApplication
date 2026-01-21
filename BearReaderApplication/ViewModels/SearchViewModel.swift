//
//  SearchViewModel.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import Observation

@MainActor
@Observable class SearchViewModel {
    var searchText = "" {
        didSet {
            performSearch(query: searchText)
        }
    }
    var filteredPosts: [TrackedPostData] = []
    
    private var searchTask: Task<Void, Never>?
    
    init() {}
    
    func loadAllPosts() {
        performSearch(query: searchText)
    }
    
    private func performSearch(query: String) {
        // Cancel the previous search task
        searchTask?.cancel()
        
        if query.isEmpty {
            filteredPosts = []
        } else {
            // Create a new task and store it
            searchTask = Task {
                // Debounce
                try? await Task.sleep(nanoseconds: 300_000_000)
                if Task.isCancelled { return }
                
                do {
                    let results = try await DatabaseManager.shared.searchPosts(query)
                    // Check if the task hasn't been cancelled and the search text is still valid
                    guard !Task.isCancelled, self.searchText == query else { return }
                    filteredPosts = results
                } catch {
                    // If search fails, clear results
                    guard !Task.isCancelled, self.searchText == query else { return }
                    filteredPosts = []
                }
            }
        }
    }
}
