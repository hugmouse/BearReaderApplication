//
//  HTMLProcessor.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import Foundation
import UIKit

// TODO: Get rid of Apple's AttributedString HTML parser since:
// - Parsing changes between iOS versions
// - They can't parse lists with <a> at the start correctly (iOS 17, iOS 18)
// - Invokes WebKit and JavascriptCore
struct HTMLProcessor {
    static func htmlToAttributedString(html: String) throws -> AttributedString {
        // TODO: Maybe this hack with styles is no longer needed
        let modifiedHTML = """
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <style>
                    body {
                        font-family: -apple-system, Helvetica, sans-serif;
                    }
                    pre, code {
                        font-family: monospace;
                    }
                    * {
                        background: unset;
                    }
                    code {
                        font-family: monospace;
                        font-size: 1rem;
                    }
                </style>
            </head>
            <body>
                \(html)
            </body>
            </html>
            """
        
        
        guard let data = modifiedHTML.data(using: .unicode) else {
            return AttributedString()
        }
        
        var options: [NSAttributedString.DocumentReadingOptionKey: Any] = [:]
        
        options = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
                
        let nsAttributedString = try NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        )
        
        var attributedString = AttributedString(nsAttributedString)
        
        // Override font size since default one is too small
        let bodyFontSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        
        for run in attributedString.runs {
            if let uiFont = run.uiKit.font {
                let newFont = uiFont.withSize(bodyFontSize)
                attributedString[run.range].uiKit.font = newFont
            }
            // Set colors for light/dark theme
            attributedString[run.range].uiKit.foregroundColor = UIColor.label
        }
        
        return attributedString
    }
}
