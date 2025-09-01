//
//  ProfileDatabaseView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var previewManager = ParserPreviewSelectorViewModel.shared
    @State private var showingResetAlert = false
    @State private var path = [Int]()
    
    var body: some View {
            List {
                Section(header: Text("API Configuration"),  footer:
                    Text("Customize the BearBlog discover page URL to match your preferred instance or if the default URL changes. This helps ensure the app continues working with different BearBlog deployments.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                ) {
                    EditableSettingsRowView(
                        title: "Service URL",
                        value: $settingsManager.serviceURL,
                        icon: "globe",
                        placeholder: "https://bearblog.dev/discover/"
                    )
                }
                
                Section(header: Text("CSS Selectors"), footer:
                    Text("These CSS selectors help the app parse BearBlog content correctly. You may need to adjust them if the website's HTML structure changes or if you're using a custom BearBlog theme. The app uses these to extract post information for a better reading experience.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                ) {
                    NavigationLink(destination: ParserDetailView(
                        title: "Posts List",
                        selector: $settingsManager.cssPostsList,
                        description: "Selector for the list of posts on the discover page",
                        icon: "list.bullet"
                    )) {
                        UnifiedRowView(title: "Posts List", icon: "list.bullet", value: settingsManager.cssPostsList)
                    }

                    NavigationLink(destination: ParserDetailView(
                        title: "Post Title",
                        selector: $settingsManager.cssPostTitle,
                        description: "Selector for extracting post titles",
                        icon: "textformat"
                    )) {
                        UnifiedRowView(title: "Post Title", icon: "textformat", value: settingsManager.cssPostTitle)
                    }

                    NavigationLink(destination: ParserDetailView(
                        title: "Post Age",
                        selector: $settingsManager.cssPostAge,
                        description: "Selector for extracting post age/date",
                        icon: "clock"
                    )) {
                        UnifiedRowView(title: "Post Age", icon: "clock", value: settingsManager.cssPostAge)
                    }

                    NavigationLink(destination: ParserDetailView(
                        title: "Post Rating",
                        selector: $settingsManager.cssPostRating,
                        description: "Selector for extracting post rating/votes",
                        icon: "star"
                    )) {
                        UnifiedRowView(title: "Post Rating", icon: "star", value: settingsManager.cssPostRating)
                    }

                    NavigationLink(destination: ParserDetailView(
                        title: "Main Content",
                        selector: $settingsManager.cssMainContent,
                        description: "Selector for extracting main post content",
                        icon: "doc.text"
                    )) {
                        UnifiedRowView(title: "Main Content", icon: "doc.text", value: settingsManager.cssMainContent)
                    }
                }
                
                Section {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.red)
                            Text("Reset to Defaults")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settingsManager.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
        .task {
            await previewManager.fetchHTMLIfNeeded(from: settingsManager.serviceURL)
        }
    }
}


struct EditableSettingsRowView: View {
    let title: String
    @Binding var value: String
    let icon: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.body)
                TextField(placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StorageView: View {
    @StateObject private var viewModel = DatabaseViewModel()
    @State private var showingDeleteAlert = false
    @State private var showingClearCacheAlert = false
    @State private var showingActivitySheet = false
    
    var body: some View {
        List {
            Section(header: Text("Database Information")) {
                UnifiedRowView(title: "Database Size", icon: "externaldrive", value: viewModel.databaseSize, valueAlignment: .trailing)
            }

            Section(header: Text("Cache Information")) {
                UnifiedRowView(title: "Total Cache Size", icon: "memorychip", value: viewModel.totalCacheSize, valueAlignment: .trailing)
                UnifiedRowView(title: "Memory Cache", icon: "cpu", value: viewModel.cacheMemoryUsage, valueAlignment: .trailing)
                UnifiedRowView(title: "Disk Cache", icon: "internaldrive", value: viewModel.cacheDiskUsage, valueAlignment: .trailing)
            }

            Section(header: Text("Storage Usage")) {
                UnifiedRowView(title: "Total Posts", icon: "doc.on.doc", value: "\(viewModel.totalPosts)", valueAlignment: .trailing)
                UnifiedRowView(title: "Read Posts", icon: "checkmark.circle", value: "\(viewModel.readPosts)", valueAlignment: .trailing)
                UnifiedRowView(title: "Encountered Posts", icon: "eye", value: "\(viewModel.encounteredPosts)", valueAlignment: .trailing)
            }
            
            Section(header: Text("Data Management")) {
                Button(action: {
                    showingActivitySheet = true
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("Export Database")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }

                Button(action: {
                    showingClearCacheAlert = true
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "trash.circle")
                            .foregroundColor(.orange)
                        Text("Clear Cache")
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }

                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Delete All Data")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                await viewModel.loadStorageInfo()
            }
        }
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteAllData()
                }
            }
        } message: {
            Text("This will permanently delete all your reading history and tracked posts. This action cannot be undone.")
        }
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearCache()
            }
        } message: {
            Text("This will clear all cached post content. You'll need to reload posts from the network next time you view them.")
        }
        .sheet(isPresented: $showingActivitySheet) {
            if let databaseURL = viewModel.getDatabaseURL() {
                ActivityViewController(activityItems: [databaseURL])
            }
        }
    }
}
