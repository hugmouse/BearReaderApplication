//
//  SearchView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 03.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import Combine

struct SearchView: View {
    @Binding var shouldFocusSearch: Bool
    @StateObject private var viewModel = SearchViewModel()
    @State private var isSearchFocused: Bool = false
    @State private var tabBarVisibility: Visibility = .visible
    
    var body: some View {
        NavigationStack() {
            VStack(spacing: 8.0) {
                if !isSearchFocused && viewModel.searchText.isEmpty {
                    HStack {
                        Text("Search")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding([.top, .leading], 16.0)
                }
                SearchBar(searchText: $viewModel.searchText, shouldFocus: $shouldFocusSearch, isSearchFocused: $isSearchFocused)
                    .padding([.top], isSearchFocused || !viewModel.searchText.isEmpty ? 16.0 : 0.0)
                    .padding([.bottom], 4.0)
                
                if viewModel.searchText.isEmpty {
                    SearchEmptyState()
                } else {
                    // Posts search section
                    if !viewModel.filteredPosts.isEmpty {
                        List {
                            Section("Posts") {
                                ForEach(viewModel.filteredPosts, id: \.id) { trackedPost in
                                    NavigationLink(destination: PostView(post: trackedPost.toPost, vis: $tabBarVisibility)) {
                                        SearchPostRowView(
                                            trackedPost: trackedPost,
                                            searchText: viewModel.searchText
                                        )
                                    }
                                    .onAppear {
                                        tabBarVisibility = .visible
                                    }
                                }
                            }
                        }
                        .toolbar(tabBarVisibility, for: .tabBar)
                        .listStyle(.plain)
                    } else {
                        SearchNoResultsState(query: viewModel.searchText)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
        .animation(.easeInOut(duration: 0.2), value: viewModel.searchText.isEmpty)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadAllPosts()
        }
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var shouldFocus: Bool
    @Binding var isSearchFocused: Bool
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search posts...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isFieldFocused)
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .onChange(of: shouldFocus) { _, newValue in
            if newValue {
                isFieldFocused = true
                shouldFocus = false
            }
        }
        .onChange(of: isFieldFocused) { _, newValue in
            isSearchFocused = newValue
        }
    }
}

struct SearchEmptyState: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Search your posts")
                .font(.title2)
                .foregroundColor(.gray)
            Text("Enter a search term to find posts you've encountered")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

struct SearchNoResultsState: View {
    let query: String
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No posts found")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
            Text("No posts match \"\(query)\"")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

struct SearchPostRowView: View {
    let trackedPost: TrackedPostData
    let searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(highlightedTitle)
                    .font(.headline)
                    .lineLimit(2)
                Text("\(trackedPost.domain)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if trackedPost.wasLoaded {
                    if trackedPost.isRead {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Image(systemName: "eye")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }

            HStack {
                HStack(alignment: .center, spacing: 2) {
                    Image(systemName: "chevron.up.2")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(trackedPost.rating)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30.0, alignment: .leading)
                }

                Spacer()

                if let lastAccessed = trackedPost.lastAccessedAt {
                    Text("Last accessed: \(lastAccessed, formatter: relativeDateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Encountered: \(trackedPost.encounteredAt, formatter: relativeDateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var highlightedTitle: AttributedString {
        var attributedString = AttributedString(trackedPost.title)
        
        if !searchText.isEmpty {
            let range = attributedString.range(of: searchText, options: .caseInsensitive)
            if let range = range {
                attributedString[range].backgroundColor = .yellow.opacity(0.3)
            }
        }
        
        return attributedString
    }
}

private let relativeDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
