//
//  ContentView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 01.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct ContentView: View {
    @State private var router = Router.shared

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
            TabView(selection: $router.selectedTab) {
                PostsView(feedType: .trending)
            .tabItem {
                Label("Trending", systemImage: "house.fill")
            }
            .tag(Tab.trending)

            PostsView(feedType: .recent)
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
    }
}

#Preview {
    ContentView()
}
