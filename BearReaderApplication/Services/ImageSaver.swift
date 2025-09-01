//
//  ImageSaver.swift
//  BearReaderApplication
//
//  Created by Iaroslav Angliuster on 28.09.25.
//
//  Copyright 2025 Iaroslav Angliuster
//


import SwiftUI

// Thanks to: https://www.hackingwithswift.com/books/ios-swiftui/how-to-save-images-to-the-users-photo-library
class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    func copyToClipboard(image: UIImage) {
        UIPasteboard.general.image = image
        print("Image copied to clipboard!")
    }

    // Wowie
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("Save finished!")
    }
}
