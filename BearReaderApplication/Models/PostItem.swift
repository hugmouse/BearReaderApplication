//
//  PostItem.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import Foundation

struct PostItem {
    let title: String
    let url: String
    let age: String
    let rating: String
    let domain: String
    let publishedAt: Date?

    init(title: String, url: String, age: String, rating: String, publishedDateString: String? = nil) {
        self.title = title
        self.url = url
        self.age = age
        self.rating = rating
        self.domain = Self.extractDomain(from: url)
        self.publishedAt = Self.parseISO8601(publishedDateString)
    }

    private static func parseISO8601(_ dateString: String?) -> Date? {
        guard let dateString else { return nil }

        // bearblog.dev uses format without seconds: "2026-01-04T19:37Z"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mmX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: dateString)
    }
    
    static func extractDomain(from url: String) -> String {
        guard let urlComponents = URL(string: url),
              let host = urlComponents.host else {
            return "unknown"
        }
        return host
    }
}

extension PostItem: Hashable, Equatable, Identifiable {
    var id: String { self.url }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: PostItem, rhs: PostItem) -> Bool {
        return lhs.url == rhs.url
    }
}
