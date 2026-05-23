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
    @State private var shouldFocusSearch = false
    @State private var router = Router.shared

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        self.selectedFeedType = .trending
    }

    var body: some View {
            TabView(selection: $router.selectedTab) {
                PostsView(selectedFeedType: $selectedFeedType)
            .tabItem {
                Label("Trending", systemImage: "house.fill")
            }
            .tag(Tab.trending)

            PostsView(selectedFeedType: $selectedFeedType)
                .tabItem {
                    Label("Recent", systemImage: "clock.fill")
                }
                .tag(Tab.recent)

                BlogsView()
            .tabItem {
                Label("Blogs", systemImage: "book.fill")
            }
            .tag(Tab.blogs)

                ProfileView()
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(Tab.profile)

                SearchView()
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(Tab.search)
        }
        .onReceive(Just(router.selectedTab)) {
            if $0 == .trending {
                self.selectedFeedType = .trending
            }
            if $0 == .recent {
                self.selectedFeedType = .recent
            }
        }
    }
}

#Preview {
    ContentView()
}
