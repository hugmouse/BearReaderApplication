//
//  InlinePostRating.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 01.11.25.
//

import SwiftUI


struct InlinePostRating: View {
    let rating: String
    
    var body: some View {
        if (rating != "") {
            HStack(alignment: .center, spacing: 2) {
                Image(systemName: "chevron.up.2")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(rating)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30.0, alignment: .leading)
            }
            
            Spacer()
        }
    }
}
