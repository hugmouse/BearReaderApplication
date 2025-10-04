//
//  ContentView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 01.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import Combine

struct ContentView: View {
    @State var selectedFeedType: FeedType
    @State private var selectedTab = 0
    @State private var shouldFocusSearch = false

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        self.selectedFeedType = .trending
    }

    var body: some View {
        TabView(selection: $selectedTab) {
                PostsView(selectedFeedType: $selectedFeedType)
            .tabItem {
                Label("Trending", systemImage: "house.fill")
            }
            .tag(0)

            PostsView(selectedFeedType: $selectedFeedType)
                .tabItem {
                    Label("Recent", systemImage: "clock.fill")
                }
                .tag(1)

                BlogsView()
            .tabItem {
                Label("Blogs", systemImage: "book.fill")
            }
            .tag(2)

                ProfileView()
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(3)

                SearchView(shouldFocusSearch: $shouldFocusSearch)
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(4)
        }
        .onReceive(Just(selectedTab)) {
            if $0 == 0 {
                self.selectedFeedType = .trending
            }
            if $0 == 1 {
                self.selectedFeedType = .recent
            }
        }
    }
}

#Preview {
    ContentView()
}
