//
//  UpvoteView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct UpvoteView: View {
    let upvote: PostUpvote

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                // Non-functional button for display purposes only
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "chevron.up.2")
                        .font(.system(size: 16, weight: .medium))
                    Text("\(upvote.count)")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(UIColor.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                )
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}
