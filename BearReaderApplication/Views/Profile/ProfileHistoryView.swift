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
    @StateObject private var viewModel = ProfileViewModel()
    @State private var tabBarVisibility: Visibility = .visible

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.historyPosts.isEmpty {
                HistoryEmptyView()
            } else {
                List {
                    ForEach(viewModel.historyPosts, id: \.id) { trackedPost in
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
                .foregroundColor(.gray)
            Text("No reading history")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
            Text("Posts you've read will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
