//
//  Image.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//

import SwiftUI

class CustomImages: ObservableObject {
    @Published var id: UUID    // UUID
    @Published var name: String    // 图片名称，不包含文件后缀
    @Published var type: WorkTaskType  // 压缩/转换
    @Published var inputURL: URL   // 输入URL
    @Published var inputType: String   // 输入文件后缀
    @Published var outputType: String  // 输出文件后缀
    
    @Published private var _image: NSImage?    // 图片
    @Published private var _thumbnail: NSImage?    // 缩略图
    @Published private var _inputSize: Int?    // 文件输入大小
    @Published private var _outputSize: Int?   // 文件输出大小
    
    // 图片状态：.pending 等待压缩 .running 正在执行 .completed 已完成 .failed 压缩失败
    @Published var isState: TaskState = .pending
    @Published var isDownload: DownloadState = .idle
    
    // 进度
    @Published private(set) var progress: Double = 0
    
    func updateProgress(_ value: Double = 0) {
        progress = min(max(value, 0), 1)
    }
    
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    init(
        id: UUID,
        name: String,
        type: WorkTaskType,
        inputURL: URL,
        inputType: String,
        outputType: String,
        isState: TaskState = .pending) {
            self.id = id
            self.name = name
            self.type = type
            self.inputURL = inputURL
            self.inputType = inputType
            self.outputType = outputType
            self.isState = isState
        }
}

    // MARK: 计算数学和方法
extension CustomImages {
    
    // 输入文件的大小
    var inputSize: Int {
        if Self.isPreview {
            return _inputSize ?? 1_234_567
        }
        return _inputSize ?? 0
    }
    
    // 输出路径,默认命名为 image.id_compress
    var outputURL: URL {
        let ext = (type == .compression ? inputType : outputType).lowercased()
        let outputURLs = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(id)_compress")
            .appendingPathExtension(ext)
        return outputURLs
    }
    
    // 输出文件的大小
    var outputSize: Int {
        if Self.isPreview {
            return _outputSize ?? 456_789
        }
        return _outputSize ?? 0
    }
    
    // 图片压缩比例
    var compressionRatio: Double {
        guard inputSize > 0, outputSize > 0 else { return 0 }
        let ratio = Double(outputSize) / Double(inputSize)
        return outputSize > inputSize ? 0 : (1 - ratio)
    }
    
    // 小写的输入文件类型
    var inputTypeLowercased: String {
        inputType.lowercased()
    }
    
    // 大写的输入文件类型
    var inputTypeUppercased: String {
        inputType.uppercased()
    }
    
    // 小写的输入文件类型
    var outputTypeLowercased: String {
        let ext = (type == .compression ? inputType : outputType).lowercased()
        return ext
    }
    
    // 大写的输入文件类型
    var outputUppercased: String {
        let ext = (type == .compression ? inputType : outputType).uppercased()
        return ext
    }
    
    // 原始文件名
    var fullName: String {
        name + "." + inputTypeLowercased
    }
    
    // 实际磁盘文件名
    var internalFileName: String {
        inputURL.lastPathComponent
    }
     
    // 懒加载图片，防止同时创建多个CustomImages时，出现卡顿的问题
    var image: NSImage? {
        if Self.isPreview {
            return NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
        }
        return _image
    }
    
    // 懒加载缩略图，
    var thumbnail: NSImage? {
        if Self.isPreview {
            return NSImage(systemSymbolName: "photo", accessibilityDescription: nil)
        }
        return _thumbnail
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
}
    
    
// MARK: - 调用方法
extension CustomImages {
    
    // 释放图片
    func releaseImage() {
        _image = nil
    }
    
    // 释放缩略图
    func releaseThumbnail() {
        _thumbnail = nil
    }
    
    // 计算输入文件大小
    func loadInputSizeIfNeeded() {
        if _inputSize == nil {
            _inputSize = FileUtils.getFileSize(fileURL: inputURL)
        }
    }
    
    // 计算输出文件大小
    func loadOutputSizeIfNeeded() {
        if _outputSize == nil {
            let input = FileUtils.getFileSize(fileURL: inputURL)
            let output = FileUtils.getFileSize(fileURL: outputURL)
            print("inputURL:\(inputURL),文件是否存在:\(FileManager.default.fileExists(atPath: outputURL.path))")
            print("outputURL:\(outputURL),文件是否存在:\(FileManager.default.fileExists(atPath: outputURL.path))")
            
            if output < input {
                _outputSize = output
            } else {
                _outputSize = input
            }
        }
    }
    
    // 加载缩略图
    func loadThumbnailIfNeeded() {
        if _thumbnail == nil {
            _thumbnail = generateThumbnail(from:inputURL,maxSize: 60)
        }
    }
    
    // 加载原图
    func loadImageIfNeeded() {
        if _image == nil {
            _image = NSImage(contentsOf: inputURL)
        }
    }
    
    // 图片用于压缩/转换
    func loadImageIfCalculate() -> NSImage? {
        if let img = _image {
            return img
        }
        
        let img = NSImage(contentsOf: inputURL)
        
        return img
    }
}

enum CustomImagesError: Error {
    case loadImageFailed
}
