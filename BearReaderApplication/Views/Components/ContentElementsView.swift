//
//  ContentElementsView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct ContentElementsView: View {
    let elements: [ContentElement]
    let onRendered: () -> Void
    @State private var renderedElementsCount = 0
    
    init(elements: [ContentElement], onRendered: @escaping () -> Void = {}) {
        self.elements = elements
        self.onRendered = onRendered
    }
    
    var body: some View {
        ForEach(Array(elements.enumerated()), id: \.offset) { index, element in
            ContentElementView(element: element) {
                renderedElementsCount += 1
                if renderedElementsCount == elements.count {
                    onRendered()
                }
            }
            .id(index)
        }
    }
}
