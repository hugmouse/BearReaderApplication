//
//  CodeBlockView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import UIKit

struct CodeBlockView: View {
    let codeText: String
    
    var body: some View {
        Text(codeText)
            .font(.system(.body, design: .monospaced))
            .padding(12)
            .background(Color(UIColor.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
            .cornerRadius(6)
    }
}
