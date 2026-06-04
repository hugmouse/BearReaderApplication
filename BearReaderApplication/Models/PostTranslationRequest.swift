//
//  PostTranslationRequest.swift
//  BearReaderApplication
//

import Foundation

struct PostTranslationRequest: Identifiable, Sendable {
    static let titleID = "post.title"

    let id: String
    let text: String
}
