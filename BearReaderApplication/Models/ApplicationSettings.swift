//
//  ApplicationSettings.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//

struct SettingsModel: Sendable {
    var serviceURL: String
    var userAgent: String
    var cssSelectors: CSSSelectors

    static let defaults = SettingsModel(
        serviceURL: "https://bearblog.dev/discover/",
        userAgent: "BearReader/1.0 (https://github.com/hugmouse/BearReaderApplication)",
        cssSelectors: CSSSelectors.defaults
    )
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
