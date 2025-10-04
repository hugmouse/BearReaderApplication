//
//  BlogSubscription.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.10.25.
//
//  Copyright 2025 Iaroslav Angliuster
//

import Foundation

struct BlogSubscription: Identifiable, Hashable, Equatable {
    let id: Int64
    let domain: String
    let feedUrl: String
    let blogTitle: String
    let subscribedAt: Date
    let lastFetchedAt: Date?

    init(id: Int64 = 0, domain: String, feedUrl: String, blogTitle: String, subscribedAt: Date = Date(), lastFetchedAt: Date? = nil) {
        self.id = id
        self.domain = domain
        self.feedUrl = feedUrl
        self.blogTitle = blogTitle
        self.subscribedAt = subscribedAt
        self.lastFetchedAt = lastFetchedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(domain)
    }

    static func == (lhs: BlogSubscription, rhs: BlogSubscription) -> Bool {
        return lhs.id == rhs.id && lhs.domain == rhs.domain
    }
}
