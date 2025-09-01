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
    
    init(title: String, url: String, age: String, rating: String) {
        self.title = title
        self.url = url
        self.age = age
        self.rating = rating
        self.domain = Self.extractDomain(from: url)
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
