//
//  SettingsManager.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @AppStorage("serviceURL") var serviceURL: String = SettingsModel.defaults.serviceURL
    @AppStorage("userAgent") var userAgent: String = SettingsModel.defaults.userAgent
    @AppStorage("cssPostsList") var cssPostsList: String = SettingsModel.defaults.cssSelectors.postsList
    @AppStorage("cssPostTitle") var cssPostTitle: String = SettingsModel.defaults.cssSelectors.postTitle
    @AppStorage("cssPostAge") var cssPostAge: String = SettingsModel.defaults.cssSelectors.postAge
    @AppStorage("cssPostRating") var cssPostRating: String = SettingsModel.defaults.cssSelectors.postRating
    @AppStorage("cssMainContent") var cssMainContent: String = SettingsModel.defaults.cssSelectors.mainContent
    
    var currentSettings: SettingsModel {
        SettingsModel(
            serviceURL: serviceURL,
            userAgent: userAgent,
            cssSelectors: CSSSelectors(
                postsList: cssPostsList,
                postTitle: cssPostTitle,
                postAge: cssPostAge,
                postRating: cssPostRating,
                mainContent: cssMainContent
            )
        )
    }
    
    func resetToDefaults() {
        serviceURL = SettingsModel.defaults.serviceURL
        userAgent = SettingsModel.defaults.userAgent
        cssPostsList = SettingsModel.defaults.cssSelectors.postsList
        cssPostTitle = SettingsModel.defaults.cssSelectors.postTitle
        cssPostAge = SettingsModel.defaults.cssSelectors.postAge
        cssPostRating = SettingsModel.defaults.cssSelectors.postRating
        cssMainContent = SettingsModel.defaults.cssSelectors.mainContent
    }
}

struct SettingsHelper {
    static func getDefaultSettings() -> SettingsModel {
        return SettingsModel.defaults
    }
}

// Sendable settings provider for background operations
final class SendableSettingsProvider: Sendable {
    static let shared = SendableSettingsProvider()

    private init() {}

    @MainActor
    func getCurrentSettings() -> SettingsModel {
        return SettingsManager.shared.currentSettings
    }

    func getDefaultSettings() -> SettingsModel {
        return SettingsModel.defaults
    }
}
