//
//  CompressionManager.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/12.
//

import SwiftUI

class CompressionManager:ObservableObject {
    @ObservedObject var appStorage = AppStorage.shared
    static let shared = CompressionManager()
    // 任务队列：存储被压缩的图片
    private var taskQueue: [CustomImages] = []
    
    // 当前有无被压缩的图片，isCompressing表示当前有图片被压缩，其他图片需要等待
    private var isCompressing = false
    
    // 进入压缩队列，开始压缩
    func enqueue(_ image: [CustomImages]) {
        // 将图片添加到任务队列
        taskQueue.append(contentsOf: image)
        compressionTask()
    }

    // 压缩任务：
    // 1、判断压缩和任务队列
    // 2、修改当前压缩状态和图片的压缩状态
    // 3、当压缩成功后，修改图片的压缩状态，移除任务队列中已经压缩图片，将当前压缩状态改为false，开始压缩下一个
    private func compressionTask() {
        // 如果当前没有被压缩的图片，获取任务队列的第一张图片，否则退出
        guard !isCompressing, let task = taskQueue.first else { return }
        
        // 设置压缩状态为 true
        isCompressing = true
        DispatchQueue.main.async {
            // 修改当前图片为压缩中
            task.compressionState = .compressing
        }

        compressImage(task) { success in
            DispatchQueue.main.async {
                task.compressionState = success ? .completed : .failed
                self.taskQueue.removeFirst()
                self.isCompressing = false
                // 如果没有压缩的任务，就显示全部压缩完成
                self.compressionTask() // 继续下一个
            }
        }
    }
    
    private func getFileSize(fileURL: URL) -> Int {
        let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
        let diskSize = resourceValues?.totalFileAllocatedSize ?? 0
        
        // 获取文件的实际大小
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
        
        // 当macOS上有图像大小，以macOS上图像字节为准。
        // 如果macOS上没有图像大小，以获取的图像字节为准。
        return diskSize > 0 ? diskSize : attributes ?? 0
        
    }
    
    // 使用 NSbitmapimagerep 压缩图片
    private func compressImage(_ image: CustomImages, completion: @escaping (Bool) -> Void) {
        let nsImage = image.image
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            // 如果转换失败，调用闭包
            completion(false)
            return
        }
        // 设置压缩率
        let properties: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: appStorage.imageCompressionRate // 范围 0.0（最小质量）到 1.0（最大质量）
        ]
        // 设置压缩格式
        var compressType:NSBitmapImageRep.FileType {
            switch image.type.uppercased() {
                case "PNG":
                    return .png
                case "GIF":
                    return .gif
                case "JPG", "JPEG":
                    return .jpeg
                case "JP2":
                    return .jpeg2000
                case "TIFF", "TIF":
                    return .tiff
                case "BMP":
                    return .bmp
                default:
                    return .png
                }
        }
        // 压缩图片并获取压缩的 Data
        let imageData = bitmap.representation(using: compressType, properties: properties)

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "." + image.type.lowercased())
        
        do {
            // 将压缩图片的 Data，写入临时文件
            try imageData?.write(to: tempURL)
            DispatchQueue.main.async {
                // 更新 Image 图片的输出大小，输出路径以及计算压缩比率
                image.outputSize = self.getFileSize(fileURL: tempURL)
                image.outputURL = tempURL
                if let outSize = image.outputSize {
                    let ratio = Double(outSize) / Double(image.inputSize)
                    image.compressionRatio = outSize > image.inputSize ? 0.0 : 1 - ratio
                } else {
                    image.compressionRatio = 0.0
                }
            }
            completion(true)
        } catch {
            print("数据写入失败")
            completion(false)
        }
    }
}
