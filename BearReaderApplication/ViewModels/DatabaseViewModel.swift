//
//  DatabaseViewModel.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import Observation

@MainActor
@Observable class DatabaseViewModel {
    var databaseSize: String = ""
    var totalPosts: Int = 0
    var readPosts: Int = 0
    var encounteredPosts: Int = 0
    var cacheMemoryUsage: String = ""
    var cacheDiskUsage: String = ""
    var totalCacheSize: String = ""
    
    private var databasePath: String? {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return nil
        }
        return "\(path)/BearReader.sqlite3"
    }

    func loadStorageInfo() async {
        if let path = databasePath {
            self.databaseSize = getDatabaseSize(at: path)
        } else {
            self.databaseSize = "Unknown"
        }

        do {
            let readPostsData = try await DatabaseManager.shared.getReadPosts()
            let allPostsData = try await DatabaseManager.shared.getAllTrackedPosts()

            self.readPosts = readPostsData.count
            self.totalPosts = allPostsData.count
            self.encounteredPosts = allPostsData.count - readPostsData.count
        } catch {
            // If database fails, set values to 0
            self.readPosts = 0
            self.totalPosts = 0
            self.encounteredPosts = 0
        }

        loadCacheInfo()
    }
    
    func deleteAllData() async {
        do {
            try await DatabaseManager.shared.clearAllData()
        } catch {
            // If clear fails, we'll still refresh the info
        }
        await loadStorageInfo()
    }
    
    func getDatabaseURL() -> URL? {
        guard let path = databasePath else { return nil }
        return URL(fileURLWithPath: path)
    }
    
    private func getDatabaseSize(at path: String) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let fileSize = attributes[.size] as? NSNumber {
                let sizeInBytes = fileSize.int64Value
                return ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
            }
        } catch {
            print("Error getting database size: \(error)")
        }
        return "Unknown"
    }

    func loadCacheInfo() {
        let cache = URLCache.shared
        let memoryUsage = cache.currentMemoryUsage
        let diskUsage = cache.currentDiskUsage
        let totalUsage = memoryUsage + diskUsage

        self.cacheMemoryUsage = ByteCountFormatter.string(fromByteCount: Int64(memoryUsage), countStyle: .file)
        self.cacheDiskUsage = ByteCountFormatter.string(fromByteCount: Int64(diskUsage), countStyle: .file)
        self.totalCacheSize = ByteCountFormatter.string(fromByteCount: Int64(totalUsage), countStyle: .file)
    }

    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        loadCacheInfo()
    }
}
