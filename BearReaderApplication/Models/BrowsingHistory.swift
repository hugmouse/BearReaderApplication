//
//  BrowsingHistory.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 11.12.25.
//

import Foundation

struct BrowsingHistory: Identifiable {
    let id: Int64
    let title: String
    let url: String
    let date: Date
    
    var toPost: PostItem {
        return PostItem(title: title, url: url, age: date.formatted(date: .long, time: .shortened), rating: "0")
    }
}
