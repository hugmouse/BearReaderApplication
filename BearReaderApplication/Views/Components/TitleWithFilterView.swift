//
//  TitleWithFilterView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 05.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct TitleWithFilterView: View {
    @Binding var selectedFeedType: FeedType
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if #available(iOS 26.0, *) {
            // iOS 26 and later: Rounded floating island
            VStack(spacing: 0) {
                HStack {
                    Text("Posts")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    HStack {
                        Picker(selection: $selectedFeedType) {
                            Text("Trending").tag(FeedType.trending)
                            Text("Recent").tag(FeedType.recent)
                        } label: {
                            Text("Posts")
                        }
                        .pickerStyle(.automatic)
                    }
                }
                .padding([.top, .bottom], 12.0)
                .padding([.leading], 16.0)
                .glassEffect()
            }
            .background(colorScheme == .dark ? darkGradient : whiteGradient)
            .padding(.horizontal)
            .zIndex(3)
        } else {
            // Previous iOS versions: Full-width block
            VStack(spacing: 0) {
                HStack {
                    Text("Posts")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    HStack {
                        Picker(selection: $selectedFeedType) {
                            Text("Trending").tag(FeedType.trending)
                            Text("Recent").tag(FeedType.recent)
                        } label: {
                            Text("Posts")
                        }
                        .pickerStyle(.automatic)
                    }
                }
                .padding([.bottom], 4.0)
                .padding([.top], 6.0)
                .padding([.leading], 16.0)
                .background(.ultraThinMaterial)
                Divider()
            }
            .zIndex(3)
        }
    }
}
