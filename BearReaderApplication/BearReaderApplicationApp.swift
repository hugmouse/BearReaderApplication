//
//  BearReaderApplicationApp.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 01.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

@main
struct BearReaderApplicationApp: App {

    init() {
        configureURLCache()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    // TODO: make configurable by the user
    private func configureURLCache() {
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB
        let diskCapacity = 1000 * 1024 * 1024 // 1  GB
        let urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
        URLCache.shared = urlCache
    }
}
