//
//  ProfileHistoryView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct HistoryView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var tabBarVisibility: Visibility = .visible

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.historyPosts.isEmpty {
                HistoryEmptyView()
            } else {
                List {
                    ForEach(viewModel.historyPosts, id: \.id) { trackedPost in
                        NavigationLink(destination: PostView(post: trackedPost.toPost, vis: $tabBarVisibility)) {
                            HistoryPostView(trackedPost: trackedPost)
                        }
                        .onAppear {
                            tabBarVisibility = .visible
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.removeItemFromBrowsingHistory(trackedPost)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listSectionSeparator(.hidden, edges: .top)
                }
                .listStyle(.plain)
            }
        }
        .toolbar(tabBarVisibility, for: .tabBar)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await viewModel.loadPosts()
            }
        }
    }
}

struct HistoryEmptyView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No reading history")
                .font(.title2)
                .foregroundStyle(.secondary)
                .padding(.top)
            Text("Posts you've read will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Browse Posts") {
                Router.shared.selectedTab = 0
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
            Spacer()
        }
    }
}
