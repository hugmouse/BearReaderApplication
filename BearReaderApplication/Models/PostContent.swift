//
//  PostContent.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//

import Foundation

struct PostImage {
    let url: String
    let altText: String
    let needsPadding: Bool
}

struct PostUpvote {
    let uid: String
    let title: String
    let count: Int
}

struct PostTag {
    let text: String
    let query: String
}

struct PostVideo {
    let embedUrl: String
    let thumbnailUrl: String
    let title: String
    let platform: String
}

enum ContentElement {
    case text(AttributedString)
    case image(PostImage)
    case codeBlock(String)
    case header2(String)
    case header3(String)
    case upvote(PostUpvote)
    case tags([PostTag])
    case video(PostVideo)
}

struct PostContent {
    let elements: [ContentElement]
}
