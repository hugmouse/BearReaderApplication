//
//  ApplicationSettings.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//

import SwiftUI

struct SettingsModel: Sendable {
    var serviceURL: String
    var userAgent: String
    var cssSelectors: CSSSelectors
    var cacheSettings: CacheSettings

    static let defaults = SettingsModel(
        serviceURL: "https://bearblog.dev/discover/",
        userAgent: "BearReader/\(Bundle.main.appBuild) (https://github.com/hugmouse/BearReaderApplication)",
        cssSelectors: CSSSelectors.defaults,
        cacheSettings: CacheSettings.defaults
    )
}

struct CacheSettings: Sendable {
    var memoryCacheMB: Int
    var diskCacheMB: Int

    var memoryCapacityBytes: Int { memoryCacheMB * 1024 * 1024 }
    var diskCapacityBytes: Int { diskCacheMB * 1024 * 1024 }

    static let defaults = CacheSettings(
        memoryCacheMB: 50,
        diskCacheMB: 1000
    )

    static let minMemoryMB = 10
    static let maxMemoryMB = 200
    static let minDiskMB = 100
    static let maxDiskMB = 5000
}

struct CSSSelectors: Sendable {
    var postsList: String
    var postTitle: String
    var postAge: String
    var postRating: String
    var mainContent: String

    static let defaults = CSSSelectors(
        postsList: "ul > li",
        postTitle: "div > a",
        postAge: "div small > small:first-of-type",
        postRating: "div small > small:last-child",
        mainContent: "main"
    )
}
