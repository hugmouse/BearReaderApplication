//
//  Router.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 16.12.25.
//

import SwiftUI
import Observation

enum Tab: Int {
    case trending = 0
    case recent = 1
    case blogs = 2
    case profile = 3
    case search = 4
}

// Used for posts notifications and posts routing
//
// When you tap on a notification, this thing pushes PostItem to the navigation stack
@Observable class Router {
    @MainActor static let shared = Router()
    var selectedTab: Tab = .trending
    var path = NavigationPath()

    func openPost(_ post: PostItem) {
        selectedTab = .trending
        path.append(post)
    }
}
