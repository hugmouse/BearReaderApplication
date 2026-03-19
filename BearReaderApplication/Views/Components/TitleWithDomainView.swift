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
    var showDomain: Bool = true

    var body: some View {
        Group {
            Text(post.title)
                .font(.headline)
            +
            Text(showDomain ? " (\(post.domain))" : "").font(.caption).foregroundColor(.secondary)
        }.lineLimit(3)
    }
}
