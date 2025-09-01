//
//  HeaderView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct HeaderView: View {
    let text: String
    let level: HeaderLevel
    
    enum HeaderLevel {
        case h2
        case h3
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(.primary)
            .padding([.bottom], 16.0)
    }
    
    private var font: Font {
        switch level {
        case .h2:
            return .title2
        case .h3:
            return .title3
        }
    }
}
