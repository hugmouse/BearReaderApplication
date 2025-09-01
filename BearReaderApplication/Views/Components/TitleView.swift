//
//  TitleView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 24.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct TitleView: View {
    var title: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if #available(iOS 26.0, *) {
            // iOS 26 and later: Rounded floating island
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding([.top, .bottom], 12.0)
                .padding([.leading], 16.0)
                .glassEffect()
            }
            .padding(.horizontal)
            .background(colorScheme == .dark ? darkGradient : whiteGradient)
            .zIndex(3)
        } else {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding([.bottom], 4.0)
                .padding([.top], 6.0)
                .padding([.leading], 16.0)
                .background(.ultraThinMaterial)
                .zIndex(3)
                Divider()
            }
        } }
}
