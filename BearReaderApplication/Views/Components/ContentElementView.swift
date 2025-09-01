//
//  ContentElementView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import SelectableText

struct ContentElementView: View {
    let element: ContentElement
    let onElementRendered: () -> Void
    @State private var textLayoutHeight: CGFloat = 0
    
    init(element: ContentElement, onElementRendered: @escaping () -> Void = {}) {
        self.element = element
        self.onElementRendered = onElementRendered
    }
    
    var body: some View {
        switch element {
        case .text(let attributedString):
            SelectableText(attributedString).padding([.bottom], -8.0).onAppear {
                onElementRendered()
            }

        case .image(let postImage):
            PostImageView(postImage: postImage)
                .onAppear {
                    onElementRendered()
                }
        case .codeBlock(let codeText):
            CodeBlockView(codeText: codeText)
                .onAppear {
                    onElementRendered()
                }
        case .header2(let text):
            HeaderView(text: text, level: .h2)
                .onAppear {
                    onElementRendered()
                }
        case .header3(let text):
            HeaderView(text: text, level: .h3)
                .onAppear {
                    onElementRendered()
                }
        case .upvote(let upvote):
            UpvoteView(upvote: upvote)
                .onAppear {
                    onElementRendered()
                }
        case .tags(let tags):
            TagsView(tags: tags)
                .onAppear {
                    onElementRendered()
                }
        case .video(let video):
            VideoView(video: video)
                .padding(.bottom, 16.0)
                .onAppear {
                    onElementRendered()
                }
        }
    }
}
