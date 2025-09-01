//
//  PostContentView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct PostContentView: View {
    let post: PostItem
    let content: PostContent?
    let contentOpacity: Double
    let onContentRendered: () -> Void
    
    init(post: PostItem, content: PostContent?, contentOpacity: Double = 1.0, onContentRendered: @escaping () -> Void = {}) {
        self.post = post
        self.content = content
        self.contentOpacity = contentOpacity
        self.onContentRendered = onContentRendered
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            Text(post.title)
                .font(.title)
                .padding([.bottom], 16.0)
            if let content = content {
                ContentElementsView(elements: content.elements, onRendered: onContentRendered)
                    .opacity(contentOpacity)
            } else {
                ErrorView(message: "Failed to load content")
            }
        }
        .padding()
    }
}
