//
//  PostView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import Translation

struct PostView: View {
    let post: PostItem
    @State private var viewModel = PostDetailViewModel()
    @State var scrolledID: Int? = 1
    @State private var hasRestoredScroll = false
    @State private var contentOpacity: Double = 0
    @Binding var tabBarVisibility: Visibility
    @Environment(\.openURL) private var openURL
    @State private var showingShareSheet = false
    @State private var translationRequestID = 0


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
                    post: displayedPost,
                    content: displayedContent,
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
        .navigationTitle(displayedPost.title)
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            tabBarVisibility = .hidden
            Task {
                contentOpacity = viewModel.content == nil ? 0 : 1
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

                    Button(action: {
                        toggleTranslation()
                    }) {
                        if viewModel.isTranslating {
                            Label("Translating…", systemImage: "translate")
                        } else {
                            Label(
                                viewModel.isTranslated ? "Show Original" : "Translate",
                                systemImage: viewModel.isTranslated ? "textformat" : "translate"
                            )
                        }
                    }
                    .disabled(viewModel.content == nil || viewModel.isTranslating)

                    Divider()

                    NavigationLink(destination: BlogFeedView(blog: previewBlog, vis: $tabBarVisibility, isPreview: true)) {
                        Label("Preview \(post.domain)", systemImage: "book")
                    }

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
            ActivityViewController(activityItems: [displayedPost.title, fullURL])
        }
        .modifier(
            PostTranslationTaskModifier(
                requestID: translationRequestID,
                makeRequests: { [post] in
                    await MainActor.run {
                        viewModel.translationRequests(forTitle: post.title)
                    }
                },
                applyTranslations: { translations in
                    await MainActor.run {
                        viewModel.applyTranslations(translations)
                        viewModel.finishTranslation()
                        HapticManager.success()
                    }
                },
                finishTranslation: {
                    await MainActor.run {
                        viewModel.finishTranslation()
                    }
                },
                failTranslation: { error in
                    await MainActor.run {
                        viewModel.failTranslation(error)
                    }
                }
            )
        )
        .alert("Translation Failed", isPresented: translationErrorBinding) {
            Button("OK", role: .cancel) {
                viewModel.translationErrorMessage = nil
            }
        } message: {
            Text(viewModel.translationErrorMessage ?? "Unable to translate this post.")
        }
    }

    private var displayedPost: PostItem {
        PostItem(
            title: viewModel.isTranslated ? (viewModel.translatedTitle ?? post.title) : post.title,
            url: post.url,
            age: post.age,
            rating: post.rating
        )
    }

    private var displayedContent: PostContent? {
        viewModel.isTranslated ? (viewModel.translatedContent ?? viewModel.content) : viewModel.content
    }

    private var fullURL: String {
        post.url.hasPrefix("//") ? "https:" + post.url : post.url
    }

    private var previewBlog: BlogSubscription {
        BlogSubscription(
            domain: post.domain,
            feedUrl: "https://\(post.domain)/blog/",
            blogTitle: post.domain
        )
    }

    private var translationErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.translationErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.translationErrorMessage = nil
                }
            }
        )
    }

    private func toggleTranslation() {
        if viewModel.isTranslated {
            viewModel.showOriginalContent()
            return
        }

        if viewModel.translatedContent != nil {
            viewModel.isTranslated = true
            return
        }

        viewModel.beginTranslation()
        if #available(iOS 18.0, *) {
            translationRequestID += 1
        } else {
            viewModel.isTranslating = false
            viewModel.translationErrorMessage = "Translation requires iOS 18 or later."
        }
    }

    
}
