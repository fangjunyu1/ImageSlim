//
//  Image.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//

import SwiftUI

class CustomImages {
    let id: UUID = UUID()
    var inputURL: URL
    let name: String
    let type: String
    let inputSize: Int
    
    
    // 懒加载图片，防止同时创建多个CustomImages时，出现卡顿的问题
    private var _image: NSImage?
    var image: NSImage? {
        if _image == nil {
            _image = NSImage(contentsOf: inputURL)
        }
        return _image
    }
    
    // 懒加载缩略图，
    private var _thumbnail: NSImage?
    var thumbnail: NSImage? {
        if _thumbnail == nil {
            _thumbnail = generateThumbnail(from:inputURL,maxSize: 35)
        }
        return _thumbnail
    }
    
    var outputSize: Int?
    var compressionRatio: Double?
    var outputURL: URL?
    var outputType: String?
    // 图片状态：.pending 等待压缩 .compressing 正在压缩 .completed 已压缩完成 .failed 压缩失败
    var compressionState:CompressionState
    var isDownloaded: Bool = false
    
    init(
        name: String,
        type: String,
        inputSize: Int,
        inputURL: URL,
        compressionState: CompressionState = .pending) {
            self.name = name
            self.type = type
            self.inputSize = inputSize
            self.inputURL = inputURL
            self.compressionState = compressionState
        }
    
    // 创建缩略图
    private func generateThumbnail(from url: URL, maxSize: CGFloat) -> NSImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(
                imageSource,
                0,
                [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxSize,
                    kCGImageSourceCreateThumbnailWithTransform: true
                ] as CFDictionary
              ) else {
            return nil
        }
        
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let thumbnail = NSImage(cgImage: cgImage, size: size)
        return thumbnail
    }
    
    // 释放图片
    func releaseImage() {
        _image = nil
    }
    
    // 释放缩略图
    func releaseThumbnail() {
        _thumbnail = nil
    }
}
