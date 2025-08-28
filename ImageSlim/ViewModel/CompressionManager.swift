//
//  CompressionManager.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/12.
//

import SwiftUI
import ImageIO
import UniformTypeIdentifiers

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
            }
            self.taskQueue.removeFirst()
            self.isCompressing = false
            // 如果没有压缩的任务，就显示全部压缩完成
            self.compressionTask() // 继续下一个
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
    
    // 压缩图片的方法，根据图片类型和第三方库启用功能，实现对应图片格式的压缩
    private func compressImage(_ image: CustomImages, completion: @escaping (Bool) -> Void) {
        guard image.inputURL != nil else {
            print("无法获取图片的输入位置，压缩失败")
            return
        }
        
        // 获取图片的大写格式
        let type = image.type.uppercased()
        
        if appStorage.enablePngquant && (type == "PNG" || type == "EXR" || type == "TIFF") {
            // 当前启用 Pngquant 并且图片格式为 PNG、EXR，使用 Pngquant 引擎压缩图片
            print("当前启用 Pngquant 并且图片格式为 PNG、EXR、TIFF，使用 Pngquant 引擎压缩图片")
            compressWithPngquant(image, completion: completion)
        } else if appStorage.enableGifsicle && type == "GIF" {
            print("当前启用 Gifsicle 并且图片格式为 GIF，使用 Gifsicle 引擎压缩图片")
            // 当前启用 Gifsicle 并且图片格式为 GIF，使用 Gifsicle 引擎压缩图片
            compressWithGifsicle(image, completion: completion)
        } else {
            // 默认 macOS 原生压缩
            print("使用 macOS 默认压缩")
            compressWithNative(image, completion: completion)
        }
    }
    
    // Pngquant的压缩比例
    private func getPngquantQualityString() -> String {
        if appStorage.imageCompressionRate == 1.0 {
            return "90-100"
        } else if appStorage.imageCompressionRate == 0.8 {
            return "65-75"
        } else if appStorage.imageCompressionRate == 0.5 {
            return "40-50"
        } else if appStorage.imageCompressionRate == 0.3 {
            return "15-25"
        } else if appStorage.imageCompressionRate == 0.0 {
            return "0-1"
        } else {
            return "0-1"
        }
    }
    
    // Gifsicle 的压缩比例
    private func getGifsicleQualityString() -> String {
        if appStorage.imageCompressionRate == 1.0 {
            return "256"
        } else if appStorage.imageCompressionRate == 0.8 {
            return "192"
        } else if appStorage.imageCompressionRate == 0.5 {
            return "128"
        } else if appStorage.imageCompressionRate == 0.3 {
            return "64"
        } else if appStorage.imageCompressionRate == 0.0 {
            return "4"
        } else {
            return "4"
        }
    }
    
    // 运行
    private func runProcess(process:Process,image:CustomImages,outputURL:URL,completion: @escaping (Bool) -> Void) {
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let fileHandle = pipe.fileHandleForReading
        
        do {
            try process.run()   // 启动
            
            process.terminationHandler = { process in
                let logData = fileHandle.readDataToEndOfFile()
                if let log = String(data: logData, encoding: .utf8) {
                    print("pngquant 日志：\n\(log)")
                }
                
                DispatchQueue.main.async { [self] in
                    // 更新 Image 图片的输出大小，输出路径以及计算压缩比率
                    
                    let compressedSize = getFileSize(fileURL: outputURL)
                    if compressedSize > image.inputSize {
                        print("压缩结果比原图大，保留原图")
                        image.outputSize = image.inputSize
                        image.outputURL = image.inputURL
                        image.compressionRatio = 0.0
                    } else {
                        image.outputSize = compressedSize
                        image.outputURL = outputURL
                        if let outSize = image.outputSize {
                            let ratio = Double(outSize) / Double(image.inputSize)
                            image.compressionRatio = outSize > image.inputSize ? 0.0 : 1 - ratio
                        } else {
                            image.compressionRatio = 0.0
                        }
                    }
                }
                
                if process.terminationStatus == 0 {
                    print("压缩完成")
                    completion(true)
                    return
                } else if process.terminationStatus == 99 {
                    print("压缩完成")
                    completion(true)
                    return
                } else {
                    print("压缩失败，退出码：\(process.terminationStatus)")
                    completion(false)
                    return
                }
            }
            
        } catch {
            print("运行 pngquant 失败：\(error)")
        }
    }
    
    // 压缩场景1、使用 Pngquant 压缩图片
    private func compressWithPngquant(_ image: CustomImages, completion: @escaping (Bool) -> Void) {
        
        print("当前已启用 Pngquant 引擎，压缩 PNG、EXR、TIFF 图片")
        guard let pngquant = Bundle.main.path(forResource: "pngquant", ofType: nil) else {
            print("pngquant not found in app bundle.")
            completion(false)
            return
        }
        
        let quality = getPngquantQualityString()
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(image.name)    // 获取outputURL
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pngquant)
        // pngquant --quality=65-80 --output "/Users/fangjunyu/Desktop/IMG_3104_compressed.png" "/Users/fangjunyu/Desktop/IMG_3104.PNG"
        process.arguments = [
            "--quality=\(quality)",
            "--force",
            "--output",
            outputURL.path,
            image.inputURL!.path]
        
        runProcess(process: process, image: image, outputURL: outputURL, completion: completion)
    }
    
    // 压缩场景2、使用 Gifsicle 压缩图片
    private func compressWithGifsicle(_ image: CustomImages, completion: @escaping (Bool) -> Void) {
        
        print("当前已启用 Gifsicle 引擎，压缩 Gif 图片")
        guard let gifsicle = Bundle.main.path(forResource: "gifsicle", ofType: nil) else {
            print("gifsicle not found in app bundle.")
            completion(false)
            return
        }
        
        let quality = getGifsicleQualityString()
        print("compressWithGifsicle - quality:\(quality)")
        
        // 图片的输出路径，位置在 Temporary 临时文件夹
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(image.name)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gifsicle)
        // gifsicle -O3 --colors 256 input.gif -o output.gif
        process.arguments = [
            "--optimize=3",
            "--colors", "\(quality)",
            image.inputURL!.path,
            "--output",
            outputURL.path]
        
        runProcess(process: process, image: image, outputURL: outputURL, completion: completion)
    }
    
    // 压缩场景3、使用 NSbitmapimagerep 压缩图片
    private func compressWithNative(_ image: CustomImages, completion: @escaping (Bool) -> Void) {
        // MARK: macOS原生压缩类CGImageDestination的变量
        // 将 NSImage 转换为 CGImage
        guard let tiffData = image.image.tiffRepresentation,
              let source = CGImageSourceCreateWithData(tiffData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            completion(false)
            return
        }
        
        // 设置压缩格式
        var imageType: CFString {
            switch image.type.uppercased() {
            case "JPG", "JPEG", "JP2":
                return UTType.jpeg.identifier as CFString
            case "HEIC":
                return UTType.heic.identifier as CFString
            case "PNG":
                return UTType.png.identifier as CFString
            case "GIF":
                return UTType.gif.identifier as CFString
            case "TIFF", "TIF":
                return UTType.tiff.identifier as CFString
            case "BMP":
                return UTType.bmp.identifier as CFString
            default:
                // 所有不支持的类型强制转换为 JPEG 再压缩
                return UTType.jpeg.identifier as CFString
            }
        }
        
        // MARK: 不启用第三方库时，使用 MacOS 原生 CGImageDestination 压缩图片
        // 创建用于接收压缩后数据的容器
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData, imageType, 1, nil) else {
            completion(false)
            return
        }
        
        // 压缩选项（0.0 = 最小质量，1.0 = 最佳质量）
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: appStorage.imageCompressionRate
        ]
        
        // 添加图像到目标
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        // 完成写入
        if CGImageDestinationFinalize(destination) {
            // 压缩图片并获取压缩的 Data
            let imageData = outputData as Data
            
            if imageData.count > image.inputSize {
                print("压缩结果比原图大，保留原图")
                // 用原始 tiffData 或原始文件数据替代
                image.outputSize = image.inputSize
                image.outputURL = image.inputURL
                image.compressionRatio = 0.0
                completion(true)
                return
            }
            // 否则使用压缩后的数据
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(image.name)
            print("outputURL:\(outputURL)")
            do {
                // 将压缩图片的 Data，写入临时文件
                try imageData.write(to: outputURL)
                DispatchQueue.main.async {
                    // 更新 Image 图片的输出大小，输出路径以及计算压缩比率
                    image.outputSize = self.getFileSize(fileURL: outputURL)
                    image.outputURL = outputURL
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
            return
        } else {
            completion(false)
            return
        }
    }
}
