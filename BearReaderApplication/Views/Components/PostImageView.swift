//
//  PostImageView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI
import Kingfisher

struct PostImageView: View {
    let postImage: PostImage
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var loadFailed = false
    @State private var loadedUIImage: UIImage?

    var body: some View {
        if loadFailed && !networkMonitor.isConnected {
            ImageOfflineView()
                .accessibilityLabel(postImage.altText)
        } else {
            Menu {
                if let imageToSave = loadedUIImage {
                    Button(action: {
                        let imageSaver = ImageSaver()
                        imageSaver.writeToPhotoAlbum(image: imageToSave)
                    }) {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }

                    Button(action: {
                        let imageSaver = ImageSaver()
                        imageSaver.copyToClipboard(image: imageToSave)
                    }) {
                        Label("Copy Image", systemImage: "doc.on.clipboard")
                    }
                }
            } label: {
                KFImage(URL(string: postImage.url))
                    .placeholder {
                        if networkMonitor.isConnected {
                            ImagePlaceholderView()
                        } else {
                            ImageOfflineView()
                        }
                    }
                    .onSuccess { result in
                        self.loadedUIImage = result.image
                        loadFailed = false
                    }
                    .onFailure { error in
                        print("Image failed to load: \(error.localizedDescription)")
                        loadFailed = true
                    }
                    .fade(duration: 0.25)
                    .cacheOriginalImage()
                    .diskCacheExpiration(.days(7))
                    .memoryCacheExpiration(.seconds(300))
                    .resizable()
                    .cornerRadius(8)
                    .aspectRatio(contentMode: .fit)
                    .accessibilityLabel(postImage.altText)
                    .onChange(of: networkMonitor.isConnected) {
                        if networkMonitor.isConnected && loadFailed {
                            loadFailed = false
                        }
                    }
            } primaryAction: {
                // Empty - tap does nothing
            }
        }
    }
}

struct ImagePlaceholderView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .aspectRatio(16/9, contentMode: .fit)
            .overlay(
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(0.8)
                    Text("Loading image...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            )
            .cornerRadius(8)
    }
}

struct ImageOfflineView: View {
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .aspectRatio(16/9, contentMode: .fit)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("Image unavailable offline")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            )
            .cornerRadius(8)
    }
}
