//
//  TagsView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct TagsView: View {
    let tags: [PostTag]

    var body: some View {
        ScrollView(.horizontal) {
            HStack{
            ForEach(tags.indices, id: \.self) { index in
                let tag = tags[index]
                
                Button(action: {
                    // Non-functional button for display purposes only
                }) {
                    Text(tag.text)
                        .lineLimit(1)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }}
        .padding(.vertical, 8)
    }
}
