//
//  BlockquoteView.swift
//  BearReaderApplication
//
//  Copyright 2025 Iaroslav Angliuster
//

import SwiftUI
import UIKit

struct BlockquoteView: View {
    let elements: [ContentElement]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(UIColor.systemGray3))
                .frame(width: 3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(elements.enumerated()), id: \.offset) { index, element in
                    ContentElementView(element: element)
                        .id(index)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Blockquote")
    }
}
