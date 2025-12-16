//
//  Router.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 16.12.25.
//

import SwiftUI

// Used for posts notifications and posts routing
//
// When you tap on a notification, this thing pushes PostItem to the navigation stack
class Router: ObservableObject {
    @MainActor static let shared = Router()
    @Published var selectedTab: Int = 0
    @Published var path = NavigationPath()
    
    func openPost(_ post: PostItem) {
        selectedTab = 0    // Switch to the Trending page (though maybe we should instead display authors blog?)
        path.append(post)
    }
}
