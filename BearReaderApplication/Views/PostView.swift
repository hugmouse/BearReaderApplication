//
//  PostView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct PostView: View {
    let post: PostItem
    @StateObject private var viewModel = PostDetailViewModel()
    @State var scrolledID: Int? = 1
    @State private var hasRestoredScroll = false
    @State private var contentOpacity: Double = 0
    @Binding var tabBarVisibility: Visibility
    @Environment(\.openURL) private var openURL
    @State private var showingShareSheet = false
    @State private var bookmarked = false
    @State private var isSubscribed = false


    init(post: PostItem, vis: Binding<Visibility>) {
        self.post = post
        self._tabBarVisibility = vis
    }
    
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                LoadingView()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage)
            } else {
                PostContentView(
                    post: post,
                    content: viewModel.content,
                    contentOpacity: contentOpacity,
                    onContentRendered: {
                        print("Content rendered, checking for scroll restoration")
                        if !hasRestoredScroll {
                            Task {
                                do {
                                    let storedViewID = try await DatabaseManager.shared.getViewID(post.url)
                                    if let storedViewID = storedViewID {
                                        await MainActor.run {
                                            scrolledID = storedViewID + 3
                                            hasRestoredScroll = true
                                            print("Restored scroll position to viewID: \(storedViewID)")
                                        }
                                    } else {
                                        await MainActor.run {
                                            hasRestoredScroll = true
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        hasRestoredScroll = true
                                    }
                                }
                            }
                        }


                        withAnimation(.easeInOut(duration: 0.2)) {
                            contentOpacity = 1.0
                        }
                    }
                ).scrollTargetLayout()
            }
            
        }
        .scrollPosition(id: $scrolledID)
        .navigationTitle(post.title)
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            Task {
                do {
                    bookmarked = try await DatabaseManager.shared.isPostBookmarked(post.url)
                    isSubscribed = try await DatabaseManager.shared.isSubscribedToBlog(domain: post.domain)
                } catch {
                    bookmarked = false
                    isSubscribed = false
                }
            }
            tabBarVisibility = .hidden
            Task {
                contentOpacity = 0
                await viewModel.loadContent(from: post.url)
            }
        }
        .onChange(of: scrolledID) { _, newValue in
            if let newValue = newValue {
                if newValue != 0 {
                    Task {
                        do {
                            try await DatabaseManager.shared.updateViewID(post.url, viewID: newValue)
                        } catch {
                            // Silent fail for view ID updates
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        let fullURL = post.url.hasPrefix("//") ? "https:" + post.url : post.url
                        if let url = URL(string: fullURL) {
                            openURL(url)
                        }
                    }) {
                        Label("Open in Default Browser", systemImage: "safari")
                    }

                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("Share Page With...", systemImage: "square.and.arrow.up")
                    }

                    Button(action: {
                        let fullURL = post.url.hasPrefix("//") ? "https:" + post.url : post.url
                        UIPasteboard.general.string = fullURL
                    }) {
                        Label("Copy URL", systemImage: "doc.on.doc")
                    }

                    Button(action: {
                        Task {
                            do {
                                try await DatabaseManager.shared.toggleBookmark(post.url)
                                await MainActor.run {
                                    bookmarked = !bookmarked
                                }
                            } catch {
                                // Silent fail for bookmark toggle
                            }
                        }
                    }) {
                        Label(
                            bookmarked ? "Remove from Bookmarks" : "Add to Bookmarks",
                            systemImage: bookmarked ? "bookmark.fill" : "bookmark"
                        )
                    }

                    Divider()

                    Button(action: {
                        Task {
                            do {
                                if isSubscribed {
                                    try await DatabaseManager.shared.unsubscribeFromBlog(domain: post.domain)
                                    await MainActor.run {
                                        isSubscribed = false
                                    }
                                } else {
                                    let blogTitle = post.domain.components(separatedBy: ".").first?.capitalized ?? post.domain
                                    let blogUrl = "https://\(post.domain)/blog/"
                                    try await DatabaseManager.shared.subscribeToBlog(domain: post.domain, feedUrl: blogUrl, blogTitle: blogTitle)
                                    await MainActor.run {
                                        isSubscribed = true
                                    }
                                }
                            } catch {
                                // subscription toggle
                            }
                        }
                    }) {
                        Label(
                            isSubscribed ? "Unsubscribe from \(post.domain)" : "Subscribe to \(post.domain)",
                            systemImage: isSubscribed ? "star.slash" : "star"
                        )
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            let fullURL = post.url.hasPrefix("//") ? "https:" + post.url : post.url
            ActivityViewController(activityItems: [post.title, fullURL])
        }
    }
    
}
