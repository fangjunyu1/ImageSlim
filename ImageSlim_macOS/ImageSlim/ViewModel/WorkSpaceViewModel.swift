//
//  WorkSpaceViewModel.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/2.
//
//  主要处理图片的压缩/转换代码
//  数组存储以及任务队列代码在 ImageArrayViewModel 文件中
//

import SwiftUI
import ImageIO
import UniformTypeIdentifiers

@MainActor
class WorkSpaceViewModel: ObservableObject {
    static var shared = WorkSpaceViewModel()
    var appStorage = AppStorage.shared
    var imageArray: ImageArrayViewModel {
        ImageArrayViewModel.shared
    }
    private init() {}
}

// MARK: - 压缩任务
extension WorkSpaceViewModel {
    
    /// 压缩质量配置
    private struct CompressionQuality {
        let pngquant: String
        let gifsicle: String
        
        static func from(rate: Double) -> CompressionQuality {
            switch rate {
            case 1.0:
                return CompressionQuality(pngquant: "90-100", gifsicle: "256")
            case 0.8:
                return CompressionQuality(pngquant: "60-75", gifsicle: "192")
            case 0.5:
                return CompressionQuality(pngquant: "40-50", gifsicle: "128")
            case 0.3:
                return CompressionQuality(pngquant: "15-25", gifsicle: "64")
            default:
                return CompressionQuality(pngquant: "15-25", gifsicle: "64")
            }
        }
    }
}

// MARK: - 压缩任务
extension WorkSpaceViewModel {
    
    // 压缩图片的方法，根据图片类型和配置选择合适的压缩引擎
    func compressImage(_ image: CustomImages) async -> Bool {
        
        // 获取图片的大写格式
        let type = image.inputTypeUppercased    // 大写文件后缀
        
        // 根据配置和文件类型选择压缩引擎
        if appStorage.enablePngquant && ["PNG","EXR","TIFF"].contains(type) {
            print("使用 Pngquant 引擎压缩 \(type) 图片")
            return await compressWithPngquant(image)
        } else if appStorage.enableGifsicle && type == "GIF" {
            print("使用 Gifsicle 引擎压缩 GIF 图片")
            return await compressWithGifsicle(image)
        } else {
            print("使用 macOS 原生压缩")
            return compressWithNative(image)
        }
    }
    
    // MARK: Pngquant 压缩
    private func compressWithPngquant(_ image: CustomImages) async -> Bool {
        guard let pngquant = Bundle.main.path(forResource: "pngquant", ofType: nil) else {
            print("pngquant 未找到")
            return false
        }
        
        let quality = CompressionQuality.from(rate: appStorage.imageCompressionRate)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pngquant)
        // pngquant --quality=65-80 --output "/Users/fangjunyu/Desktop/IMG_3104_compressed.png" "/Users/fangjunyu/Desktop/IMG_3104.PNG"
        process.arguments = [
            "--quality=\(quality.pngquant)",
            "--force",
            "--output", image.outputURL.path,
            image.inputURL.path]
        
        return await runProcess(process, for: image,engineName: "pngquant")
    }
    
    // MARK: Gifsicle 压缩
    private func compressWithGifsicle(_ image: CustomImages) async -> Bool {
        guard let gifsicle = Bundle.main.path(forResource: "gifsicle", ofType: nil) else {
            print("gifsicle 未找到")
            return false
        }
        
        let quality = CompressionQuality.from(rate: appStorage.imageCompressionRate)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gifsicle)
        // gifsicle -O3 --colors 256 input.gif -o output.gif
        process.arguments = [
            "--optimize=3",
            "--colors", quality.gifsicle,
            image.inputURL.path,
            "--output", image.outputURL.path]
        
        return await runProcess(process, for: image,engineName: "gifsicle")
    }
    
    
    // MARK: macOS 原生压缩
    private func compressWithNative(_ image: CustomImages) -> Bool {
        // 将 NSImage 转换为 CGImage
        guard let tiffData = image.image?.tiffRepresentation,
              let source = CGImageSourceCreateWithData(tiffData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            print("无法获取 CGImage")
            return false
        }
        
        // 获取目标格式
        let imageType = getUTType(for: image.inputType.uppercased())
        
        // 创建输出容器
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData,
            imageType,
            1,
            nil
        ) else {
            print("无法创建 CGImageDestination")
            return false
        }
        
        // 压缩选项（0.0 = 最小质量，1.0 = 最佳质量）
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: appStorage.imageCompressionRate
        ]
        
        // 添加图像到目标
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            print("图片压缩失败")
            return false
        }
        
        // 完成写入
        // 压缩图片并获取压缩的 Data
        let compressedData = outputData as Data
        
        // 如果压缩后反而变大，保留原图
        if compressedData.count >= image.inputSize {
            print("压缩后体积未减小，使用原图")
            do {
                try FileManager.default.copyItem(at: image.inputURL, to: image.outputURL)
                return true
            } catch {
                print("复制原图失败:\(error.localizedDescription)")
                return false
            }
        }
        
        // 写入压缩后的数据
        do {
            try compressedData.write(to: image.outputURL)
            print("压缩完成:\(image.outputURL)")
            return true
        } catch {
            print("写入失败")
            return false
        }
    }
    
    // 运行程序
    private func runProcess(
        _ process:Process,
        for image:CustomImages,
        engineName: String
    ) async -> Bool {
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let fileHandle = pipe.fileHandleForReading
        
        do {
            try process.run()   // 启动
        } catch {
            print("启动 \(engineName) 失败：\(error.localizedDescription)")
            return false
        }
        
        return await withCheckedContinuation { const in
            process.terminationHandler = { process in
                let logData = fileHandle.readDataToEndOfFile()
                if let log = String(data: logData, encoding: .utf8), !log.isEmpty {
                    print("\(engineName) 日志：\(log)")
                }
                
                if process.terminationStatus == 0 {
                    print("\(engineName) 压缩完成")
                    const.resume(returning: true)
                } else if process.terminationStatus == 99 {
                    print("\(engineName) 压缩后和原图一致，返回码 99")
                    const.resume(returning: false)
                } else {
                    print("\(engineName) 压缩失败，退出码：\(process.terminationStatus)")
                    const.resume(returning: false)
                }
            }
        }
    }
}

// MARK: 转换任务
extension WorkSpaceViewModel {
    
    // 转换任务：
    // 1、判断转换和任务队列
    // 2、修改当前转换状态和图片的转换状态
    // 3、当转换成功后，修改图片的转换状态，移除任务队列中已经转换图片，将当前转换状态改为false，开始转换下一个
    
    // 使用 Core Graphics 转换图片
    func conversionImage(_ image: CustomImages) -> Bool {
        // 获取CGImage
        guard let tiffData = image.image?.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmap.cgImage else {
            print("无法获取 CGImage")
            return false
        }
        
        // Step 2: 创建目标 Data 容器
        let outputData = NSMutableData()
        let targetType = getUTType(for: appStorage.convertTypeState)
        
        // Step 4: 创建 CGImageDestination
        guard let destination = CGImageDestinationCreateWithData(
            outputData,
            targetType,
            1,
            nil
        ) else {
            print("无法创建 CGImageDestination")
            return false
        }
        
        // Step 5: 设置压缩参数
        let options: CFDictionary = [:] as CFDictionary
        
        // Step 6: 添加图像并写入
        CGImageDestinationAddImage(destination, cgImage, options)
        
        guard CGImageDestinationFinalize(destination) else {
            print("图片转换失败")
            return false
        }
        
        // Step 7: 写入文件
        let imageData = outputData as Data
        do {
            try imageData.write(to: image.outputURL)
            print("转换完成: \(image.outputURL.path)")
            return true
        } catch {
            print("数据写入失败: \(error.localizedDescription)")
            return false
        }
    }
    
    private func getUTType(for format: String) -> CFString {
        let upperFormat = format.uppercased()
        
        switch upperFormat {
        case "JPG", "JPEG":
            return UTType.jpeg.identifier as CFString
        case "PNG":
            return UTType.png.identifier as CFString
        case "HEIC":
            return UTType.heic.identifier as CFString
        case "HEIF":
            return UTType.heif.identifier as CFString
        case "GIF":
            return UTType.gif.identifier as CFString
        case "TIFF", "TIF":
            return UTType.tiff.identifier as CFString
        case "BMP":
            return UTType.bmp.identifier as CFString
        case "WEBP":
            return UTType.webP.identifier as CFString
        case "JP2", "J2K", "JPF", "JPX", "JPM":
            return UTType.jpeg2000.identifier as CFString
        case "PDF":
            return UTType.pdf.identifier as CFString
        default:
            print("不支持的格式 '\(format)'，默认使用 PNG")
            return UTType.png.identifier as CFString
        }
    }
    
    // 重载方法以支持 ConverType 枚举
    private func getUTType(for converType: ConversionTypeState) -> CFString{
        return getUTType(for: converType.rawValue)
    }
}
