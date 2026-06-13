//
//  PostsView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 03.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import UIKit

struct PostsView: View {
    let feedType: FeedType

    @State private var viewModel: PostsViewModel
    @State private var router = Router.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var tabBarVisibility: Visibility = .visible
    @State private var hasPlayedErrorHaptic = false

    init(feedType: FeedType) {
        self.feedType = feedType
        self._viewModel = State(initialValue: PostsViewModel(feedType: feedType))
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack(alignment: .top) {
                if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                    VStack {
                        Image(systemName: viewModel.isOffline ? "wifi.slash" : "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(viewModel.isOffline ? .red : .orange)
                            .accessibilityHidden(true)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await viewModel.loadInitialPosts()
                            }
                        }
                        .accessibilityLabel("Retry loading posts")
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        if !hasPlayedErrorHaptic {
                            HapticManager.error()
                            hasPlayedErrorHaptic = true
                        }
                    }
                } else if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("Loading posts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.posts.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 12) {
                        Text("No posts found")
                            .foregroundStyle(.secondary)
                        Button("Refresh") {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Offline banner
                        if let errorMessage = viewModel.errorMessage, viewModel.isOffline && !viewModel.posts.isEmpty {
                            HStack {
                                Image(systemName: "wifi.slash")
                                    .foregroundColor(.white)
                                    .accessibilityHidden(true)
                                Text(errorMessage)
                                    .foregroundColor(.white)
                                    .font(.caption)
                                Spacer()
                                Button("Retry") {
                                    Task {
                                        await viewModel.refresh()
                                    }
                                }
                                .accessibilityLabel("Retry loading posts")
                                .foregroundColor(.white)
                                .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.8))
                        }
                        
                        List {
                            ForEach(viewModel.posts, id: \.url) { post in
                                NavigationLink(value: post) {
                                    PostRowView(post: post)
                                }
                                .accessibilityIdentifier("PostRow")
                                .onAppear {
                                    tabBarVisibility = .visible
                                    if viewModel.shouldLoadMore(currentItem: post) {
                                        Task {
                                            await viewModel.loadMorePosts()
                                        }
                                    }
                                }
                            }
                            .listSectionSeparator(.hidden, edges: .top)


                            if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .accessibilityHidden(true)
                                    Text("Loading more...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .listStyle(.inset)
                        .refreshable {
                            await viewModel.refresh()
                        }
                    }
                    // Can't put this inside of List for whatever reason
                    .navigationDestination(for: PostItem.self) { post in
                        PostView(post: post, vis: $tabBarVisibility)
                    }
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black, location: 0),
                                    .init(color: .clear, location: 1.0)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 50)
                            Color.white
                        }
                        .edgesIgnoringSafeArea(.all)
                    }
                }
            }
        }
        .toolbar(tabBarVisibility, for: .tabBar)
        .onAppear {
            viewModel.refreshIfStaleAfterVisit()
            if !viewModel.posts.isEmpty {
                hasPlayedErrorHaptic = false
            }
        }
        .onChange(of: settingsManager.titleBlacklist) {
            viewModel.applyTitleBlacklist()
        }
    }
}

struct PostRowView: View {
    let post: PostItem
    var showDomain: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TitleWithDomainView(post: post, showDomain: showDomain)

            HStack {
                if let publishedAt = post.publishedAt {
                    TimelineView(.everyMinute) { _ in
                        Text(formatRelativeTime(from: publishedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(post.age)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func formatRelativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
        let relativeString = formatter.localizedString(for: date, relativeTo: Date())
        return "Published \(relativeString)"
    }
}
