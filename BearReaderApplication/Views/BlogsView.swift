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
    @State private var lastBackgroundRefresh: Date?
    @StateObject private var permissionManager = NotificationPermissionManager()

    var body: some View {
        NavigationStack {
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
                                HStack {
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

                                    Spacer()

                                    if blog.newPostsCount > 0 {
                                        Text("\(blog.newPostsCount)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.accentColor)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onAppear {
                                tabBarVisibility = .visible
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                Task {
                                    await viewModel.markBlogAsViewed(domain: blog.domain)
                                }
                            })
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.unsubscribe(from: viewModel.subscribedBlogs[index])
                                }
                            }
                        }
                        .listSectionSeparator(.hidden, edges: .top)
                    }
                    .listStyle(.inset)
                    .refreshable {
                        await viewModel.refreshAllBlogs()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadSubscribedBlogs()
                    await viewModel.checkAndRefreshIfNeeded()
                    loadLastBackgroundRefresh()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                loadLastBackgroundRefresh()
            }
        }
    }

    private func loadLastBackgroundRefresh() {
        lastBackgroundRefresh = UserDefaults.standard.object(forKey: "lastBackgroundRefresh") as? Date
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
