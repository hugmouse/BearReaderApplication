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

struct TabBarAccessor: UIViewControllerRepresentable {
    var onReselect: () -> Void
    
    func makeUIViewController(context: Context) -> TabObserver {
        TabObserver()
    }
    
    func updateUIViewController(_ uiViewController: TabObserver, context: Context) {
        uiViewController.onReselect = onReselect
    }
    
    class TabObserver: UIViewController, UITabBarControllerDelegate {
        var onReselect: (() -> Void)?
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            tabBarController?.delegate = self
        }
        
        func tabBarController(_ tbc: UITabBarController, shouldSelect vc: UIViewController) -> Bool {
            // Check if the user is tapping the already active tab and check for "Search"
            if unsafe vc == tbc.selectedViewController && tbc.selectedIndex == 4 {
                onReselect?()
            }
            return true
        }
    }
}

struct ContentView: View {
    @State var selectedFeedType: FeedType
    @State private var selectedTab = 0
    @State private var shouldFocusSearch = false
    @StateObject private var router = Router.shared

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

                SearchView()
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(4)
        }
        .onReceive(Just(router.selectedTab)) {
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
