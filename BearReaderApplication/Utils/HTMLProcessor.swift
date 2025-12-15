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
import DTCoreText

struct HTMLProcessor {
    static func htmlToAttributedString(html: String) throws -> AttributedString {
        guard let data = html.data(using: .utf8) else {
            return AttributedString()
        }

        let defaultFont = UIFont.preferredFont(forTextStyle: .body)

        let parsingOptions: [String: Any] = [
            DTUseiOS6Attributes: true,
            DTDefaultFontFamily: defaultFont.familyName,
            DTDefaultFontName: defaultFont.fontName,
            DTDefaultFontSize: defaultFont.pointSize,
            DTDefaultStyleSheet: DTCSSStylesheet(styleBlock: defaultCSS) as Any,
            DTDefaultLinkDecoration: false
        ]

        guard let builder = DTHTMLAttributedStringBuilder(html: data, options: parsingOptions, documentAttributes: nil) else {
            return AttributedString()
        }

        guard let attributedString = builder.generatedAttributedString() else {
            return AttributedString()
        }

        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        applyColorSchemeSupport(mutableAttributedString)

        return (try? AttributedString(mutableAttributedString, including: \.uiKit)) ?? AttributedString()
    }

    private static func applyColorSchemeSupport(_ attributedString: NSMutableAttributedString) {
        attributedString.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: attributedString.length))
    }

    private static var defaultCSS: String {
        """
        body {
            font-family: -apple-system, Helvetica, sans-serif;
            margin: 0;
            padding: 0;
        }
        p,i,a,b,h1,h2,h3,h4,h5,h6,span {
            margin: 0;
            padding: 0;
        }
        """
    }
}
