//
//  LoadingView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView("Loading post...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
