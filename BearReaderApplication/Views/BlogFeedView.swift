//
//  BlogFeedView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.10.25.
//
//  Copyright 2025 Iaroslav Angliuster
//

import SwiftUI
import os.log

struct BlogFeedView: View {
    private let logger = Logger(subsystem: "BearReader", category: "BlogFeedView")
    let blog: BlogSubscription
    @Binding var tabBarVisibility: Visibility
    
    @State private var viewModel: BlogFeedViewModel
    @State private var showingUnsubscribeAlert = false
    @Environment(\.dismiss) private var dismiss
    private let isPreview: Bool
    
    init(blog: BlogSubscription, vis: Binding<Visibility>, isPreview: Bool = false) {
        self.blog = blog
        self._tabBarVisibility = vis
        self._viewModel = State(initialValue: BlogFeedViewModel(domain: blog.domain))
        self.isPreview = isPreview
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
        .toolbar {
            if !isPreview {
                trailingToolbar
            }
        }
        .alert("Unsubscribe", isPresented: $showingUnsubscribeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unsubscribe", role: .destructive) {
                Task {
                    do {
                        try await DatabaseManager.shared.unsubscribeFromBlog(domain: blog.domain)
                    } catch {
                        logger.error("Failed to unsubscribe from \(blog.domain): \(error.localizedDescription)")
                    }
                    HapticManager.warning()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to unsubscribe from \(blog.blogTitle)?")
        }
        .task(id: blog.domain) {
            await viewModel.loadFeed(updateLastFetched: !isPreview)
            if !isPreview {
                await viewModel.markAsRead()
            }
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
                    PostRowView(post: post, showDomain: false)
                }
                .accessibilityIdentifier("PostRow")
                .onAppear { tabBarVisibility = .visible }
            }
            .listStyle(.inset)
            .refreshable { await viewModel.refresh(updateLastFetched: !isPreview) }
        }
    }
    
    private func offlineBanner(message: String) -> some View {
        HStack {
            Label(message, systemImage: "wifi.slash")
                .font(.caption)
            Spacer()
            Button("Retry") { Task { await viewModel.refresh(updateLastFetched: !isPreview) } }
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
                Button("Retry") { Task { await viewModel.loadFeed(updateLastFetched: !isPreview) } }
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
                    .accessibilityLabel("Unsubscribe from \(blog.blogTitle)")
            }
        }
    }
    
}
