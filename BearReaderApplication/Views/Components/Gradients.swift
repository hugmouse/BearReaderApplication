//
//  Gradients.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 25.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

let darkGradient = LinearGradient(
    gradient: Gradient(stops: [
        .init(color: Color(white: 0.0, opacity: 0.75), location: 0),
        .init(color: .clear, location: 0.9)
    ]),
    startPoint: .top,
    endPoint: .bottom
)

let whiteGradient = LinearGradient(
    gradient: Gradient(stops: [
        .init(color: Color(white: 1.0, opacity: 0.75), location: 0),
        .init(color: .clear, location: 0.9)
    ]),
    startPoint: .top,
    endPoint: .bottom
    )
