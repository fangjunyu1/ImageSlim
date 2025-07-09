//
//  Image.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//

import SwiftUI

struct CustomImages {
    var id: UUID
    var image: NSImage
    var name: String
    var type: String
    var inputSize: Int
    var outputSize: Int?
    var compressionRatio: Double?
}
