//
//  TableView.swift
//  BearReaderApplication
//

import SwiftUI

struct TableView: View {
    let table: PostTable

    @State private var availableWidth: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                if !table.headers.isEmpty {
                    GridRow {
                        ForEach(Array(table.headers.enumerated()), id: \.offset) { _, header in
                            Text(header)
                                .font(.body.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                        }
                    }
                    .background(Color(UIColor.systemGray5))
                    .accessibilityAddTraits(.isHeader)

                    Divider()
                }

                ForEach(Array(table.rows.enumerated()), id: \.offset) { rowIndex, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(cell)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                        }
                    }

                    if rowIndex < table.rows.count - 1 {
                        Divider()
                    }
                }
            }
            .frame(minWidth: availableWidth)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            availableWidth = width
        }
        .background(Color(UIColor.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
        )
        .cornerRadius(6)
        .accessibilityElement(children: .contain)
    }
}
