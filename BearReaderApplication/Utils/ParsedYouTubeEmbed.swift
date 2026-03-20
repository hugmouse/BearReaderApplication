//
//  ParsedYouTubeEmbed.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 14.12.25.
//

import Foundation

struct ParsedYouTubeEmbed {
    let embedURL: URL
    let thumbnailURL: URL
    let title: String
    let videoID: String
}

let WhitelistYoutubeHosts: Set<String> = [
    "www.youtube.com",
    "youtube.com",
    "www.youtube-nocookie.com",
    "youtube-nocookie.com"
]

let WhitelistYoutubeChars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")

func parseYouTubeEmbed(from rawURL: String, title rawTitle: String?) -> ParsedYouTubeEmbed? {
    guard let url = URL(string: rawURL),
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        return nil
    }

    guard let scheme = components.scheme,
          scheme == "https" else {
        return nil
    }

    guard let host = components.host,
          WhitelistYoutubeHosts.contains(host) else {
        return nil
    }

    // Expected: /embed/VIDEO_ID
    let pathComponents = components.path.split(separator: "/")
    // ["embed", "VIDEO_ID"]
    guard pathComponents.count == 2,
          pathComponents[0] == "embed" else {
        return nil
    }

    let videoID = String(pathComponents[1])

    if videoID.isEmpty || videoID.rangeOfCharacter(from: WhitelistYoutubeChars.inverted) != nil {
        return nil
    }

    var embedComponents = URLComponents()
    embedComponents.scheme = "https"
    embedComponents.host = host
    embedComponents.path = "/embed/\(videoID)"

    guard let safeEmbedURL = embedComponents.url else {
        return nil
    }

    var thumbnailComponents = URLComponents()
    thumbnailComponents.scheme = "https"
    thumbnailComponents.host = "img.youtube.com"
    thumbnailComponents.path = "/vi/\(videoID)/maxresdefault.jpg"

    guard let thumbnailURL = thumbnailComponents.url else {
        return nil
    }

    let title = (rawTitle?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap {
        $0.isEmpty ? nil : $0
    } ?? "Video"

    return ParsedYouTubeEmbed(
        embedURL: safeEmbedURL,
        thumbnailURL: thumbnailURL,
        title: title,
        videoID: videoID
    )
}
