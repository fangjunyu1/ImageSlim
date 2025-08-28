//
//  ConversionManager.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/8/25.
//

import SwiftUI
import ImageIO
import UniformTypeIdentifiers

class ConversionManager:ObservableObject {
    @ObservedObject var appStorage = AppStorage.shared
    static let shared = ConversionManager()
    // 任务队列：存储被转换的图片
    private var taskQueue: [CustomImages] = []
    
    // 当前有无被转换的图片，isCompressing = true，表示当前有图片被转换，其他图片需要等待
    private var isConversion = false
    
    // 进进入转换队列，开始压缩
    func enqueue(_ image: [CustomImages]) {
        // 将图片添加到任务队列
        taskQueue.append(contentsOf: image)
        conversionTask()
    }
    
    // 转换任务：
    // 1、判断转换和任务队列
    // 2、修改当前转换状态和图片的转换状态
    // 3、当转换成功后，修改图片的转换状态，移除任务队列中已经转换图片，将当前转换状态改为false，开始转换下一个
    private func conversionTask() {
        // 如果当前没有被转换的图片，获取任务队列的第一张图片，否则退出
        guard !isConversion, let task = taskQueue.first else { return }
        
        // 设置转换状态为 true
        isConversion = true
        DispatchQueue.main.async {
            // 修改当前图片为压缩中
            task.compressionState = .compressing
        }
        
        conversionImage(task) { success in
            DispatchQueue.main.async {
                task.compressionState = success ? .completed : .failed
            }
            self.taskQueue.removeFirst()
            self.isConversion = false
            // 如果没有转换的任务，就显示全部转换完成
            self.conversionTask() // 继续下一个
        }
    }
    
    private func getFileSize(fileURL: URL) -> Int {
        // Finder上的图片大小
        //        let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
        //        let diskSize = resourceValues?.totalFileAllocatedSize ?? 0
        //        print("Finder上的图片大小：\(diskSize)")
        
        // 获取文件的实际大小
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
        print("文件的实际大小：\(attributes ?? 0)")
        
        // 当macOS上有图像大小，以macOS上图像字节为准。
        // 如果macOS上没有图像大小，以获取的图像字节为准。
        return attributes ?? 0
        
    }
    
    // 转换图片的方法，根据图片类型和第三方库启用功能，实现对应图片格式的转换
    private func conversionImage(_ image: CustomImages, completion: @escaping (Bool) -> Void) {
        guard image.inputURL != nil else {
            print("无法获取图片的输入位置，压缩失败")
            return
        }
        
        conversionWithNative(image, completion: completion)
    }
    
    // 使用 Core Graphics 转换图片
    private func conversionWithNative(_ image: CustomImages, completion: @escaping (Bool) -> Void) {
        // MARK: macOS 原生转换类 Core Graphics
        // 获取CGImage
        guard let tiffData = image.image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmap.cgImage else {
            print("无法获取 CGImage")
            completion(false)
            return
        }
        
        // Step 2: 创建目标 Data 容器
        let outputData = NSMutableData()
        
        // Step 3: 从转换格式中获取格式，构建为 UTType 格式。
        var uttypeID: CFString {
            var id = UTType.jpeg.identifier
            switch appStorage.convertTypeState {
            case .jpg, .jpeg:
                id = UTType.jpeg.identifier
            case .png:
                id = UTType.png.identifier
            case .tif, .tiff:
                id = UTType.tiff.identifier
            case .gif:
                id = UTType.gif.identifier
            case .bmp:
                id = UTType.bmp.identifier
            case .heif:
                id = UTType.heif.identifier
            case .heic:
                id = UTType.heic.identifier
            case .jp2, .j2k, .jpf, .jpx, .jpm:
                id = UTType.jpeg2000.identifier
            case .ico:
                id = UTType.ico.identifier
            case .pdf:
                id = UTType.pdf.identifier
            case .svg:
                id = UTType.svg.identifier
            case .webp:
                id = UTType.webP.identifier
            case .raw, .cr2, .nef, .arw, .dng, .orf, .rw2:
                id = UTType.rawImage.identifier
            }
            return id as CFString
        }
        
        // Step 4: 创建 CGImageDestination
        guard let destination = CGImageDestinationCreateWithData(outputData, uttypeID, 1, nil) else {
            print("无法创建 CGImageDestination")
            completion(false)
            return
        }
        
        // Step 5: 设置压缩参数
        let options: CFDictionary = [:] as CFDictionary
        
        // Step 6: 添加图像并写入
        CGImageDestinationAddImage(destination, cgImage, options)
        CGImageDestinationFinalize(destination)
        
        let imageData = outputData as Data
        
        let imageName = (image.name as NSString).deletingPathExtension
        let imageFullName = (imageName as NSString).appendingPathExtension("\(appStorage.convertTypeState.rawValue.lowercased())") ?? "error.png"
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(imageFullName)
        print("outputURL:\(outputURL)")
        do {
            // 将转换图片的 Data，写入临时文件
            try imageData.write(to: outputURL)
            DispatchQueue.main.async { [self] in
                // 更新 Image 图片的输出大小，输出路径以及计算压缩比率
                image.outputSize = self.getFileSize(fileURL: outputURL)
                image.outputURL = outputURL
                if let outSize = image.outputSize {
                    let ratio = Double(outSize) / Double(image.inputSize)
                    image.compressionRatio = outSize > image.inputSize ? 0.0 : 1 - ratio
                } else {
                    image.compressionRatio = 0.0
                }
                image.outputType = appStorage.convertTypeState.rawValue.uppercased()
            }
            completion(true)
        } catch {
            print("数据写入失败")
            completion(false)
        }
    }
}
