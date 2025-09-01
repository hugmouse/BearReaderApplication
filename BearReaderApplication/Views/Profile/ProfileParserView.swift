//
//  ProfileParserView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct ParserPreviewResult {
    let matchCount: Int
    let matchedElements: [String]
    let isValid: Bool
    let errorMessage: String?
}

struct ParserDetailView: View {
    let title: String
    @Binding var selector: String
    let description: String
    let icon: String
    
    @StateObject private var previewManager = ParserPreviewSelectorViewModel.shared
    @State private var previewResult: ParserPreviewResult?
    
    var body: some View {
        List {
            Section(header: Text("CSS Selector")) {
                VStack {
                    HStack(spacing: 16) {
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title)
                                .font(.headline)
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    TextField("Enter CSS selector...", text: $selector, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Section(header: HStack {
                Text("Preview")
                Spacer()
                if previewManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button("Refresh HTML") {
                        Task {
                            await previewManager.refreshHTML()
                            updatePreview()
                        }
                    }
                    .font(.caption)
                }
            }) {
                ParserPreviewView(
                    previewResult: previewResult,
                    errorMessage: previewManager.errorMessage
                )
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: selector) { _, _ in
            updatePreview()
        }
        .onAppear {
            updatePreview()
            Task {
                await previewManager.fetchHTMLIfNeeded(from: SettingsManager.shared.serviceURL)
                updatePreview()
            }
        }
    }
    
    private func updatePreview() {
        previewResult = previewManager.previewSelector(selector)
    }
}

struct ParserPreviewView: View {
    let previewResult: ParserPreviewResult?
    let errorMessage: String?
    
    var body: some View {
        Group {
            if let errorMessage = errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.caption)
            } else if let result = previewResult {
                if result.isValid {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Found \(result.matchCount) matches")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        if !result.matchedElements.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sample matches (index, element):")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ForEach(Array(result.matchedElements.enumerated()), id: \.offset) { index, element in
                                    Text("\(index + 1). '\(element)'")
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(4)
                                }
                                
                                if result.matchCount > result.matchedElements.count {
                                    Text("... and \(result.matchCount - result.matchedElements.count) more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                            }
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        VStack(alignment: .leading) {
                            Text("Invalid selector")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let errorMessage = result.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
            } else {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.secondary)
                    Text("Enter a CSS selector to see preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}
