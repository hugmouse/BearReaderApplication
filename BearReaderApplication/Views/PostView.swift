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
    @State private var viewModel = PostDetailViewModel()
    @State var scrolledID: Int? = 1
    @State private var hasRestoredScroll = false
    @State private var contentOpacity: Double = 0
    @Binding var tabBarVisibility: Visibility
    @Environment(\.openURL) private var openURL
    @State private var showingShareSheet = false


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
                                if let position = await viewModel.restoreScrollPosition(url: post.url) {
                                    scrolledID = position
                                }
                                hasRestoredScroll = true
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
            tabBarVisibility = .hidden
            Task {
                contentOpacity = 0
                async let statusLoad: Void = viewModel.loadPostStatus(
                    url: post.url,
                    title: post.title,
                    domain: post.domain
                )
                async let contentLoad: Void = viewModel.loadContent(from: post.url)
                _ = await (statusLoad, contentLoad)
            }
        }
        .onChange(of: scrolledID) { _, newValue in
            if let newValue = newValue, newValue != 0 {
                Task {
                    await viewModel.updateScrollPosition(url: post.url, viewID: newValue)
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
                        HapticManager.success()
                    }) {
                        Label("Copy URL", systemImage: "doc.on.doc")
                    }

                    Button(action: {
                        Task {
                            await viewModel.toggleBookmark(url: post.url)
                        }
                    }) {
                        Label(
                            viewModel.isBookmarked ? "Remove from Bookmarks" : "Add to Bookmarks",
                            systemImage: viewModel.isBookmarked ? "bookmark.fill" : "bookmark"
                        )
                    }

                    Divider()

                    Button(action: {
                        Task {
                            await viewModel.toggleSubscription(
                                domain: post.domain,
                                currentlySubscribed: viewModel.isSubscribed
                            )
                        }
                    }) {
                        Label(
                            viewModel.isSubscribed ? "Unsubscribe from \(post.domain)" : "Subscribe to \(post.domain)",
                            systemImage: viewModel.isSubscribed ? "star.slash" : "star"
                        )
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .accessibilityLabel("Post actions")
                }
                .accessibilityIdentifier("PostMenuButton")
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            let fullURL = post.url.hasPrefix("//") ? "https:" + post.url : post.url
            ActivityViewController(activityItems: [post.title, fullURL])
        }
    }
    
}
