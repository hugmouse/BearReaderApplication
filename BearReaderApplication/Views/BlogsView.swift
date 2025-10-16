//
//  BlogsView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.10.25.
//
//  Copyright 2025 Iaroslav Angliuster
//

import SwiftUI

struct BlogsView: View {
    @StateObject private var viewModel = BlogsViewModel()
    @State private var tabBarVisibility: Visibility = .visible

    var body: some View {
        NavigationStack {
            HStack {
                Text("Blogs")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding([.top, .leading], 16.0)
            .padding([.bottom], -12.0)
            ZStack {
                if viewModel.isLoading && viewModel.subscribedBlogs.isEmpty {
                    ProgressView("Loading blogs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.subscribedBlogs.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No Subscribed Blogs")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Discover blogs on Trending/Recent tabs and subscribe to your favorites")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.subscribedBlogs) { blog in
                            NavigationLink(destination: BlogFeedView(blog: blog, vis: $tabBarVisibility)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(blog.blogTitle)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text(blog.domain)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let lastFetched = blog.lastFetchedAt {
                                        Text("Updated \(formatLastFetched(lastFetched))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Not fetched yet")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onAppear {
                                tabBarVisibility = .visible
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.unsubscribe(from: viewModel.subscribedBlogs[index])
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                    .padding([.top], 4.0)
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 20)
                            Color.black
                        }
                        .edgesIgnoringSafeArea(.all)
                    }
                    .refreshable {
                        await viewModel.refreshAllBlogs()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadSubscribedBlogs()
                    await viewModel.checkAndRefreshIfNeeded()
                }
            }
        }
        .toolbar(tabBarVisibility, for: .tabBar)
    }
}



    private func formatLastFetched(_ date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)

        if minutes < 60 {
            return minutes < 1 ? "just now" : "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else if days < 7 {
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
