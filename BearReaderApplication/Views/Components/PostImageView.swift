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
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var loadFailed = false
    @State private var loadedUIImage: UIImage?
    @State private var isPreviewPresented = false

    var body: some View {
        if loadFailed && !networkMonitor.isConnected {
            ImageOfflineView()
                .accessibilityLabel(postImage.altText)
        } else {
            Menu {
                if let imageToSave = loadedUIImage {
                    Button(action: {
                        saveToPhotos(imageToSave)
                    }) {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }

                    Button(action: {
                        copyImage(imageToSave)
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
                if loadedUIImage != nil {
                    isPreviewPresented = true
                }
            }
            .fullScreenCover(isPresented: $isPreviewPresented) {
                if let loadedUIImage {
                    FullscreenImagePreview(image: loadedUIImage, altText: postImage.altText)
                }
            }
        }
    }

    private func saveToPhotos(_ image: UIImage) {
        let imageSaver = ImageSaver()
        imageSaver.writeToPhotoAlbum(image: image)
        HapticManager.success()
    }

    private func copyImage(_ image: UIImage) {
        let imageSaver = ImageSaver()
        imageSaver.copyToClipboard(image: image)
        HapticManager.success()
    }
}

private enum ImagePreviewConstants {
    static let minimumZoomScale: CGFloat = 1.0
    static let maximumZoomScale: CGFloat = 5.0
    static let zoomStep: CGFloat = 1.5
    static let zoomScaleTolerance: CGFloat = 0.01
}

private struct FullscreenImagePreview: View {
    let image: UIImage
    let altText: String
    @Environment(\.dismiss) private var dismiss
    @State private var zoomScale = ImagePreviewConstants.minimumZoomScale
    @State private var controlsVisible = true

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .ignoresSafeArea()

            ZoomableImageView(image: image, zoomScale: $zoomScale) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    controlsVisible.toggle()
                }
            }
            .accessibilityLabel(altText)
            .ignoresSafeArea()

            if controlsVisible {
                previewControls
                    .transition(.opacity)
            }
        }
    }

    private var previewControls: some View {
        HStack(spacing: 16) {
            Button {
                zoomScale = max(ImagePreviewConstants.minimumZoomScale, zoomScale / ImagePreviewConstants.zoomStep)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.title2)
            }
            .accessibilityLabel("Zoom out")
            .disabled(zoomScale <= ImagePreviewConstants.minimumZoomScale)

            Button {
                zoomScale = min(ImagePreviewConstants.maximumZoomScale, zoomScale * ImagePreviewConstants.zoomStep)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.title2)
            }
            .accessibilityLabel("Zoom in")
            .disabled(zoomScale >= ImagePreviewConstants.maximumZoomScale)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
            }
            .accessibilityLabel("Close image preview")
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(.black.opacity(0.6), in: Capsule())
        .padding()
    }
}

private struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    @Binding var zoomScale: CGFloat
    let onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(zoomScale: $zoomScale, onTap: onTap)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = ImagePreviewConstants.minimumZoomScale
        scrollView.maximumZoomScale = ImagePreviewConstants.maximumZoomScale
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .black

        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tapRecognizer.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tapRecognizer)

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        context.coordinator.imageView = imageView
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.zoomScale = $zoomScale
        context.coordinator.onTap = onTap

        if context.coordinator.imageView?.image !== image {
            context.coordinator.imageView?.image = image
        }

        if abs(scrollView.zoomScale - zoomScale) > ImagePreviewConstants.zoomScaleTolerance {
            context.coordinator.isApplyingSwiftUIZoom = true
            scrollView.setZoomScale(zoomScale, animated: false)
            context.coordinator.isApplyingSwiftUIZoom = false
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        var zoomScale: Binding<CGFloat>
        var onTap: () -> Void
        var isApplyingSwiftUIZoom = false

        init(zoomScale: Binding<CGFloat>, onTap: @escaping () -> Void) {
            self.zoomScale = zoomScale
            self.onTap = onTap
        }

        @objc func handleTap() {
            onTap()
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard !isApplyingSwiftUIZoom else { return }

            DispatchQueue.main.async { [zoomScale] in
                if abs(zoomScale.wrappedValue - scrollView.zoomScale) > ImagePreviewConstants.zoomScaleTolerance {
                    zoomScale.wrappedValue = scrollView.zoomScale
                }
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
                        .accessibilityHidden(true)
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
                        .accessibilityHidden(true)
                    Text("Image unavailable offline")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            )
            .cornerRadius(8)
    }
}
