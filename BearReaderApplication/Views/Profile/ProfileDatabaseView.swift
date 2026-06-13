//
//  ProfileDatabaseView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var previewManager = ParserPreviewSelectorViewModel.shared
    @State private var showingResetAlert = false
    @State private var newBlacklistTerm = ""
    @State private var path = [Int]()

    
    var body: some View {
            List {
                Section(header: Text("API Configuration"),  footer:
                    Text("Customize the BearBlog discover page URL to match your preferred instance or if the default URL changes.")
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

                Section(header: Text("Muted Title Keywords"), footer:
                    Text("Hide posts from Trending and Recent when their title contains any keyword or phrase.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                ) {
                    HStack {
                        TextField("Keyword or phrase", text: $newBlacklistTerm)
                            .submitLabel(.done)
                            .onSubmit(addBlacklistTerm)

                        Button(action: addBlacklistTerm) {
                            Image(systemName: "plus.circle.fill")
                                .accessibilityHidden(true)
                        }
                        .accessibilityLabel("Add muted keyword")
                        .disabled(trimmedBlacklistTerm.isEmpty)
                    }

                    if settingsManager.titleBlacklistTerms.isEmpty {
                        Text("No muted keywords")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(settingsManager.titleBlacklistTerms.enumerated()), id: \.offset) { _, term in
                            Text(term)
                        }
                        .onDelete(perform: removeBlacklistTerms)
                    }
                }
                
                Section(header: Text("CSS Selectors"), footer:
                    Text("These CSS selectors help the app parse BearBlog content correctly. You may need to adjust them if the website's HTML structure changes. The app uses these to extract post information for a better reading experience.")
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
                        settingsManager.hasSeenOnboarding = false
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "hand.wave")
                                .accessibilityHidden(true)
                            Text("Show Onboarding")
                            Spacer()
                        }
                    }
                }

                Section {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.red)
                                .accessibilityHidden(true)
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
                HapticManager.warning()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
        .task {
            await previewManager.fetchHTMLIfNeeded(from: settingsManager.serviceURL)
        }
    }

    private var trimmedBlacklistTerm: String {
        newBlacklistTerm.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addBlacklistTerm() {
        let term = trimmedBlacklistTerm
        guard !term.isEmpty else { return }
        defer { newBlacklistTerm = "" }

        var terms = settingsManager.titleBlacklistTerms
        guard !terms.contains(where: { $0.caseInsensitiveCompare(term) == .orderedSame }) else { return }

        terms.append(term)
        updateBlacklist(with: terms)
    }

    private func removeBlacklistTerms(at offsets: IndexSet) {
        var terms = settingsManager.titleBlacklistTerms
        terms.remove(atOffsets: offsets)
        updateBlacklist(with: terms)
    }

    private func updateBlacklist(with terms: [String]) {
        settingsManager.titleBlacklist = terms.joined(separator: "\n")
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
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.body)
                TextField(placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .submitLabel(.done)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StorageView: View {
    @State private var viewModel = DatabaseViewModel()
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingDeleteAlert = false
    @State private var showingClearCacheAlert = false
    @State private var showingActivitySheet = false
    @State private var showingImportConfirmation = false
    @State private var showingFileImporter = false
    @State private var importResultMessage: String?
    @State private var showingImportResult = false

    var body: some View {
        List {
            Section(header: Text("Database Information")) {
                UnifiedRowView(title: "Database Size", icon: "externaldrive", value: viewModel.databaseSize, valueAlignment: .trailing)
            }

            Section(header: Text("Cache Usage")) {
                UnifiedRowView(title: "Total Cache Size", icon: "memorychip", value: viewModel.totalCacheSize, valueAlignment: .trailing)
                UnifiedRowView(title: "Memory Cache", icon: "cpu", value: viewModel.cacheMemoryUsage, valueAlignment: .trailing)
                UnifiedRowView(title: "Disk Cache", icon: "internaldrive", value: viewModel.cacheDiskUsage, valueAlignment: .trailing)
            }

            Section(header: Text("Cache Limits"), footer: Text("Changes take effect immediately. Reducing limits will clear cached data.")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cpu")
                            .frame(width: 16)
                            .accessibilityHidden(true)
                        Text("Memory Cache Limit")
                        Spacer()
                        Text("\(settingsManager.memoryCacheMB) MB")
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(settingsManager.memoryCacheMB) },
                            set: { settingsManager.memoryCacheMB = Int($0) }
                        ),
                        in: Double(CacheSettings.minMemoryMB)...Double(CacheSettings.maxMemoryMB),
                        step: 10
                    )
                    .onChange(of: settingsManager.memoryCacheMB) {
                        settingsManager.applyURLCacheSettings()
                        viewModel.loadCacheInfo()
                    }
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "internaldrive")
                            .frame(width: 16)
                            .accessibilityHidden(true)
                        Text("Disk Cache Limit")
                        Spacer()
                        Text(diskCacheLimitText)
                            .foregroundColor(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(settingsManager.diskCacheMB) },
                            set: { settingsManager.diskCacheMB = Int($0) }
                        ),
                        in: Double(CacheSettings.minDiskMB)...Double(CacheSettings.maxDiskMB),
                        step: 100
                    )
                    .onChange(of: settingsManager.diskCacheMB) {
                        settingsManager.applyURLCacheSettings()
                        viewModel.loadCacheInfo()
                    }
                }
                .padding(.vertical, 4)
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
                            .accessibilityHidden(true)
                        Text("Export Database")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }

                Button(action: {
                    showingImportConfirmation = true
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.blue)
                            .accessibilityHidden(true)
                        Text("Import Database")
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
                            .accessibilityHidden(true)
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
                            .accessibilityHidden(true)
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
                    HapticManager.warning()
                }
            }
        } message: {
            Text("This will permanently delete all your reading history and tracked posts. This action cannot be undone.")
        }
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearCache()
                HapticManager.warning()
            }
        } message: {
            Text("This will clear all cached post content. You'll need to reload posts from the network next time you view them.")
        }
        .alert("Import Database", isPresented: $showingImportConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Continue") {
                showingFileImporter = true
            }
        } message: {
            Text("This will replace all your current data with the imported database. This action cannot be undone.")
        }
        .alert("Import Result", isPresented: $showingImportResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importResultMessage ?? "")
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType.database, .init(filenameExtension: "sqlite3")].compactMap { $0 },
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let accessed = url.startAccessingSecurityScopedResource()
                Task {
                    defer {
                        if accessed { url.stopAccessingSecurityScopedResource() }
                    }
                    do {
                        try await viewModel.importDatabase(from: url)
                        importResultMessage = "Database imported successfully."
                    } catch DatabaseError.invalidDatabaseFile {
                        importResultMessage = "The selected file is not a valid Bear Reader database."
                    } catch {
                        importResultMessage = "Import failed: \(error.localizedDescription)"
                    }
                    showingImportResult = true
                }
            case .failure(let error):
                importResultMessage = "Could not select file: \(error.localizedDescription)"
                showingImportResult = true
            }
        }
        .sheet(isPresented: $showingActivitySheet) {
            if let databaseURL = viewModel.getDatabaseURL() {
                ActivityViewController(activityItems: [databaseURL])
            }
        }
    }

    private var diskCacheLimitText: String {
        if settingsManager.diskCacheMB >= 1000 {
            let gb = Double(settingsManager.diskCacheMB) / 1000.0
            return "\(gb.formatted(.number.precision(.fractionLength(1)))) GB"
        } else {
            return "\(settingsManager.diskCacheMB) MB"
        }
    }
}
