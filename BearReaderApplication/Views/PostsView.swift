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
    @Binding var selectedFeedType: FeedType
    @StateObject private var trendingViewModel = PostsViewModel(feedType: .trending)
    @StateObject private var recentViewModel = PostsViewModel(feedType: .recent)
    @State private var tabBarVisibility: Visibility = .visible
    
    private var currentViewModel: PostsViewModel {
        switch selectedFeedType {
        case .trending:
            return trendingViewModel
        case .recent:
            return recentViewModel
        }
    }
    
    var body: some View {
        NavigationStack() {
            ZStack(alignment: .top) {
                if let errorMessage = currentViewModel.errorMessage, currentViewModel.posts.isEmpty {
                    VStack {
                        Image(systemName: currentViewModel.isOffline ? "wifi.slash" : "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(currentViewModel.isOffline ? .red : .orange)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await currentViewModel.loadInitialPosts()
                            }
                        }
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if currentViewModel.isLoading && currentViewModel.posts.isEmpty {
                    ProgressView("Loading posts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if currentViewModel.posts.isEmpty && !currentViewModel.isLoading {
                    Text("No posts found")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Offline banner
                        if let errorMessage = currentViewModel.errorMessage, currentViewModel.isOffline && !currentViewModel.posts.isEmpty {
                            HStack {
                                Image(systemName: "wifi.slash")
                                    .foregroundColor(.white)
                                Text(errorMessage)
                                    .foregroundColor(.white)
                                    .font(.caption)
                                Spacer()
                                Button("Retry") {
                                    Task {
                                        await currentViewModel.refresh()
                                    }
                                }
                                .foregroundColor(.white)
                                .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.8))
                        }
                        
                        List {
                            ForEach(currentViewModel.posts, id: \.url) { post in
                                NavigationLink(destination: PostView(post: post, vis: $tabBarVisibility)) {
                                    PostRowView(post: post)
                                }
                                .onAppear {
                                    tabBarVisibility = .visible
                                    if currentViewModel.loadMoreContentIfNeeded(currentItem: post) {
                                        Task {
                                            await currentViewModel.loadMorePosts()
                                        }
                                    }
                                }
                            }
                            
                            if currentViewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
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
                            await currentViewModel.refresh()
                        }
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
            Task {
                await currentViewModel.loadInitialPosts()
            }
        }
        .onChange(of: selectedFeedType) {
            Task {
                await currentViewModel.loadInitialPosts()
            }
        }
    }
}

struct PostRowView: View {
    let post: PostItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TitleWithDomainView(post: post)
            
            HStack {
                HStack(alignment: .center, spacing: 2) {
                    Image(systemName: "chevron.up.2")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(post.rating)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30.0, alignment: .leading)
                }
                
                Spacer()
                
                Text(post.age)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
