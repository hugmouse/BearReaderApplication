//
//  BlogFeedView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.10.25.
//
//  Copyright 2025 Iaroslav Angliuster
//

import SwiftUI

struct BlogFeedView: View {
    let blog: BlogSubscription
    @Binding var tabBarVisibility: Visibility
    
    @StateObject private var viewModel: BlogFeedViewModel
    @State private var showingUnsubscribeAlert = false
    @Environment(\.dismiss) private var dismiss
    
    init(blog: BlogSubscription, vis: Binding<Visibility>) {
        self.blog = blog
        self._tabBarVisibility = vis
        self._viewModel = StateObject(wrappedValue: BlogFeedViewModel(domain: blog.domain))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView("Fetching Feed...")
            } else if viewModel.posts.isEmpty {
                emptyStateOverlay
            } else {
                feedContent
            }
        }
        .navigationTitle(blog.blogTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { trailingToolbar }
        .alert("Unsubscribe", isPresented: $showingUnsubscribeAlert) {
            alertButtons
        } message: {
            Text("Are you sure you want to unsubscribe from \(blog.blogTitle)?")
        }
        .task(id: blog.domain) {
            await viewModel.loadFeed()
        }
    }
    
    // TODO: move those views into separate files?
    
    @ViewBuilder
    private var feedContent: some View {
        VStack(spacing: 0) {
            if let error = viewModel.errorMessage, viewModel.isOffline {
                offlineBanner(message: error)
            }
            
            List(viewModel.posts, id: \.url) { post in
                NavigationLink(destination: PostView(post: post, vis: $tabBarVisibility)) {
                    PostRowView(post: post)
                }
                .onAppear { tabBarVisibility = .visible }
            }
            .listStyle(.inset)
            .refreshable { await viewModel.refresh() }
        }
    }
    
    private func offlineBanner(message: String) -> some View {
        HStack {
            Label(message, systemImage: "wifi.slash")
                .font(.caption)
            Spacer()
            Button("Retry") { Task { await viewModel.refresh() } }
                .font(.caption).bold()
        }
        .padding()
        .background(.red.opacity(0.8))
        .foregroundStyle(.white)
    }
    
    @ViewBuilder
    private var emptyStateOverlay: some View {
        if let error = viewModel.errorMessage {
            ContentUnavailableView {
                Label(error, systemImage: viewModel.isOffline ? "wifi.slash" : "exclamationmark.triangle")
            } actions: {
                Button("Retry") { Task { await viewModel.loadFeed() } }
            }
        } else {
            ContentUnavailableView("No Posts", systemImage: "tray", description: Text("This blog is currently empty."))
        }
    }
    
    
    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingUnsubscribeAlert = true } label: {
                Image(systemName: "star.slash")
            }
        }
    }
    
    @ViewBuilder
    private var alertButtons: some View {
        Button("Cancel", role: .cancel) { }
        Button("Unsubscribe", role: .destructive) {
            Task {
                try? await DatabaseManager.shared.unsubscribeFromBlog(domain: blog.domain)
                dismiss()
            }
        }
    }
}
