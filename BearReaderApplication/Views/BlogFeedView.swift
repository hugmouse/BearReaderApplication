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
    @StateObject private var viewModel: BlogFeedViewModel
    @Binding var tabBarVisibility: Visibility
    @State private var showingUnsubscribeAlert = false
    @Environment(\.dismiss) private var dismiss

    init(blog: BlogSubscription, vis: Binding<Visibility>) {
        self.blog = blog
        self._tabBarVisibility = vis
        self._viewModel = StateObject(wrappedValue: BlogFeedViewModel(domain: blog.domain))
    }

    var body: some View {
        ZStack(alignment: .top) {
            if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                VStack {
                    Image(systemName: viewModel.isOffline ? "wifi.slash" : "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(viewModel.isOffline ? .red : .orange)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task {
                            await viewModel.loadFeed()
                        }
                    }
                    .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView("Loading feed...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.posts.isEmpty && !viewModel.isLoading {
                Text("No posts found in this blog")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    // Offline banner
                    if let errorMessage = viewModel.errorMessage, viewModel.isOffline && !viewModel.posts.isEmpty {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.white)
                            Text(errorMessage)
                                .foregroundColor(.white)
                                .font(.caption)
                            Spacer()
                            Button("Retry") {
                                Task {
                                    await viewModel.refresh()
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
                        ForEach(viewModel.posts, id: \.url) { post in
                            NavigationLink(destination: PostView(post: post, vis: $tabBarVisibility)) {
                                PostRowView(post: post)
                            }
                            .onAppear {
                                tabBarVisibility = .visible
                            }
                        }
                    }
                    .listStyle(.inset)
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .navigationTitle(blog.blogTitle)
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingUnsubscribeAlert = true
                }) {
                    Image(systemName: "star.slash")
                }
            }
        }
        .alert("Unsubscribe from Blog", isPresented: $showingUnsubscribeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unsubscribe", role: .destructive) {
                Task {
                    do {
                        try await DatabaseManager.shared.unsubscribeFromBlog(domain: blog.domain)
                        dismiss()
                    } catch {
                        // Silent fail, or show error
                    }
                }
            }
        } message: {
            Text("Are you sure you want to unsubscribe from \(blog.blogTitle)?")
        }
        .onAppear {
            Task {
                await viewModel.loadFeed()
            }
        }
    }
}
