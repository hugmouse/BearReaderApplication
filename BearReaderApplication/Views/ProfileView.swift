//
//  ProfileView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 03.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import Combine
import SwiftSoup

struct ProfileView: View {  
    var body: some View {
        NavigationStack() {
            HStack {
                Text("Profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding([.top, .leading], 16.0)
            .padding([.bottom], -12.0)
                List {
                    NavigationLink(destination: SettingsView()) {
                        UnifiedRowView(
                            title: "Settings",
                            icon: "gearshape"
                        )
                    }
                    
                    NavigationLink(destination: HistoryView()) {
                        UnifiedRowView(
                            title: "History",
                            icon: "clock"
                        )
                    }

                    NavigationLink(destination: BookmarksView()) {
                        UnifiedRowView(
                            title: "Bookmarks",
                            icon: "bookmark"
                        )
                    }
                    
                    NavigationLink(destination: StorageView()) {
                        UnifiedRowView(
                            title: "Storage",
                            icon: "externaldrive"
                        )
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        UnifiedRowView(
                            title: "About",
                            icon: "info.circle"
                        )
                    }
                }.listStyle(.plain)
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
        }
    }
}

struct UnifiedRowView: View {
    let title: String
    let icon: String
    let value: String?
    let valueAlignment: HorizontalAlignment
    
    init(title: String, icon: String, value: String? = nil, valueAlignment: HorizontalAlignment = .leading) {
        self.title = title
        self.icon = icon
        self.value = value
        self.valueAlignment = valueAlignment
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
            }
            Spacer()
            if let value = value {
                VStack(alignment: valueAlignment) {
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProfilePostRowView: View {
    let trackedPost: TrackedPostData

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TitleWithDomainView(post: trackedPost.toPost)

            HStack {
                HStack(alignment: .center, spacing: 2) {
                    Image(systemName: "chevron.up.2")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(trackedPost.rating)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30.0, alignment: .leading)
                    Spacer()
                    if let lastAccessed = trackedPost.lastAccessedAt {
                        Text("Last read: \(lastAccessed, formatter: relativeDateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(trackedPost.age)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}


@MainActor
class ProfileViewModel: ObservableObject {
    @Published var historyPosts: [TrackedPostData] = []
    @Published var bookmarkedPosts: [TrackedPostData] = []


    private var cancellables = Set<AnyCancellable>()

    func loadPosts() async {
        do {
            let readPosts = try await DatabaseManager.shared.getReadPosts()
            historyPosts = (readPosts).sorted { $0.lastAccessedAt ?? $0.encounteredAt > $1.lastAccessedAt ?? $1.encounteredAt }
        } catch {
            historyPosts = []
        }
    }

    func loadBookmarkedPosts() async {
        do {
            let bookmarked = try await DatabaseManager.shared.getBookmarkedPosts()
            bookmarkedPosts = bookmarked.sorted { $0.lastAccessedAt ?? $0.encounteredAt > $1.lastAccessedAt ?? $1.encounteredAt }
        } catch {
            bookmarkedPosts = []
        }
    }

    func removePost(_ post: TrackedPostData) async {
        do {
            try await DatabaseManager.shared.removeTrackedPost(post.url)
        } catch {
            // Silent fail for post removal
        }
        await loadPosts()
    }
}

private let relativeDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    NavigationView {
        ProfileView()
    }
}
