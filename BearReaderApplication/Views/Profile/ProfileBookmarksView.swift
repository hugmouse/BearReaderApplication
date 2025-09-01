//
//  ProfileBookmarksView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct BookmarksView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var tabBarVisibility: Visibility = .visible

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.bookmarkedPosts.isEmpty {
                BookmarksEmptyView()
            } else {
                List {
                    ForEach(viewModel.bookmarkedPosts, id: \.id) { trackedPost in
                        NavigationLink(destination: PostView(post: trackedPost.toPost, vis: $tabBarVisibility)) {
                            ProfilePostRowView(trackedPost: trackedPost)
                        }
                        .onAppear {
                            tabBarVisibility = .visible
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar(tabBarVisibility, for: .tabBar)
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await viewModel.loadBookmarkedPosts()
            }
        }
    }
}

struct BookmarksEmptyView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "bookmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No bookmarks")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
            Text("Posts you bookmark will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
