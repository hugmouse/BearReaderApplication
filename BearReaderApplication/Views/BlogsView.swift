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
    @State private var viewModel = BlogsViewModel()
    @State private var tabBarVisibility: Visibility = .visible
    @State private var lastBackgroundRefresh: Date?
    @State private var permissionManager = NotificationPermissionManager()
    @State private var router = Router.shared

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
                            .accessibilityHidden(true)

                        Text("No Subscribed Blogs")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Discover blogs on Trending/Recent tabs and subscribe to your favorites")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button("Discover Blogs") {
                            router.selectedTab = 0
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.subscribedBlogs) { blog in
                            NavigationLink(destination: BlogFeedView(blog: blog, vis: $tabBarVisibility)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(blog.blogTitle)
                                                .font(.headline)
                                                .lineLimit(1)
                                            
                                            if blog.isNotificationsMuted {
                                                Image(systemName: "bell.slash.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .accessibilityLabel("Notifications muted")
                                            }
                                        }

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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.unsubscribe(from: blog)
                                        HapticManager.warning()
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                     Task {
                                         await viewModel.toggleNotificationsMuted(for: blog)
                                         HapticManager.success()
                                     }
                                 } label: {
                                     Label(blog.isNotificationsMuted ? "Unmute" : "Mute",
                                           systemImage: blog.isNotificationsMuted ? "bell.fill" : "bell.slash.fill")
                                 }
                                 .tint(blog.isNotificationsMuted ? .green : .orange)
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
            .overlay(alignment: .bottom) {
                if viewModel.showUndoToast {
                    HStack {
                        Text("Unsubscribed")
                            .foregroundColor(.primary)
                        Spacer()
                        Button("Undo") {
                            Task {
                                await viewModel.undoDelete()
                            }
                        }
                        .accessibilityLabel("Undo unsubscribe")
                        .bold()
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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

}