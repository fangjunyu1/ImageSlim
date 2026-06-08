//
//  ExtensionNSImage.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/6/8.
//

import AppKit

extension NSImage {
    func jpegData(compressionQuality: CGFloat = 0.9) -> Data? {
        guard let cgImage = self.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        ) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = self.size

        return bitmapRep.representation(
            using: .jpeg,
            properties: [
                .compressionFactor: compressionQuality
            ]
        )
    }
}
