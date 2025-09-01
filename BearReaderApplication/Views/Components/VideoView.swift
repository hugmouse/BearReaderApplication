//
//  VideoView.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 04.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

struct VideoView: View {
    let video: PostVideo

    var body: some View {
        Button(action: {
            openVideo()
        }) {
            ZStack {
                // Video thumbnail or placeholder
                AsyncImage(url: URL(string: video.thumbnailUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(UIColor.systemGray5))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(
                            VStack {
                                Image(systemName: "video")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text(video.platform)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
                .clipped()
                .cornerRadius(8)

                // Play button overlay
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .offset(x: 2)
                    )

                // Platform badge
                HStack {
                    Spacer()
                    VStack {
                        HStack {
                            Text(video.platform)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(video.platform == "YouTube" ? 1.0 : 0.8))
                                .cornerRadius(4)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
        )
    }

    private func openVideo() {
        var videoUrl = video.embedUrl

        if video.platform == "YouTube" {
            if let videoId = video.embedUrl.components(separatedBy: "/").last?.components(separatedBy: "?").first {
                videoUrl = "https://www.youtube.com/watch?v=\(videoId)"
            }
        }

        if let url = URL(string: videoUrl) {
            UIApplication.shared.open(url)
        }
    }
}
