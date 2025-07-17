//
//  Image.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//

import SwiftUI

class CustomImages: ObservableObject, Identifiable {
    let id: UUID
    let image: NSImage
    let name: String
    let fullName: String
    let type: String
    let inputSize: Int
    
    @Published var outputSize: Int?
    @Published var compressionRatio: Double?
    @Published var inputURL: URL?
    @Published var outputURL: URL?
    // 图片状态：.pending 等待压缩 .compressing 正在压缩 .completed 已压缩完成 .failed 压缩失败
    @Published var compressionState:CompressionState
    @Published var isDownloaded: Bool = false
    
    init(id: UUID = UUID(),
         image: NSImage,
         name: String,
         fullName: String,
         type: String,
         inputSize: Int,
         outputSize: Int? = nil,
         compressionRatio: Double? = nil,
         inputURL: URL? = nil,
         outputURL: URL? = nil,
         compressionState: CompressionState = .pending) {
        self.id = id
        self.image = image
        self.name = name
        self.fullName = fullName
        self.type = type
        self.inputSize = inputSize
        self.inputURL = inputURL
        self.outputSize = outputSize
        self.compressionRatio = compressionRatio
        self.outputURL = outputURL
        self.compressionState = compressionState
    }
}
