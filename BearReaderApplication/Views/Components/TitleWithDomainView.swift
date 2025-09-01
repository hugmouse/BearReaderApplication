//
//  TitleWithDomainView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct TitleWithDomainView: View {
    let post: PostItem
    
    var body: some View {
        Group {
            Text(post.title)
                .font(.headline)
            +
            Text(" (\(post.domain))").font(.caption).foregroundColor(.secondary)
        }.lineLimit(3)
    }
}
