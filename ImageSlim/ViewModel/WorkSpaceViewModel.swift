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
        let cwebp: Double
        
        // 0.25 和 0.75 为新增的图片压缩率，0.3 和 0.8为之前的图片压缩率。
        static func from(rate: Double) -> CompressionQuality {
            switch rate {
            case 1.0:
                return CompressionQuality(pngquant: "90-100", gifsicle: "256", cwebp: 95)
            case 0.8:
                return CompressionQuality(pngquant: "60-75", gifsicle: "192", cwebp: 80)
            case 0.75:
                return CompressionQuality(pngquant: "60-75", gifsicle: "192", cwebp: 80)
            case 0.5:
                return CompressionQuality(pngquant: "40-50", gifsicle: "128", cwebp: 60)
            case 0.3:
                return CompressionQuality(pngquant: "15-25", gifsicle: "64", cwebp: 40)
            case 0.25:
                return CompressionQuality(pngquant: "15-25", gifsicle: "64",cwebp: 40)
            default:
                return CompressionQuality(pngquant: "15-25", gifsicle: "64", cwebp: 35)
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
        // cwebp 无法压缩 webp 格式图片，这里不作为压缩引擎使用
        if appStorage.enablePngquant && ["PNG","EXR","TIFF"].contains(type) {
            print("使用 Pngquant 引擎压缩 \(type) 图片")
            return await compressWithPngquant(image)
        } else if appStorage.enableGifsicle && type == "GIF" {
            print("使用 Gifsicle 引擎压缩 GIF 图片")
            return await compressWithGifsicle(image)
        } else if appStorage.enableCwebp && type == "WEBP"{
            print("使用 Cwebp 引擎压缩 WEBP 图片")
            return await compressWithCwebp(image)
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
    
    // MARK: Cwebp 压缩
    func compressWithCwebp(_ image: CustomImages) async -> Bool {
        guard let cwebp = Bundle.main.path(forResource: "cwebp", ofType: nil) else {
            print("cwebp 未找到")
            return false
        }

        // 图片输入格式
        let inputType = image.inputTypeUppercased
        
        // cwebp 支持的格式：JPEG, WebP
        let cwebpSupportedFormats = ["JPG", "JPEG", "WEBP"]
        
        var actualInputURL = image.inputURL
        var needsCleanup = false
        
        // 如果输入格式不被 cwebp 支持，先转换 PNG 作为中间格式
        if !cwebpSupportedFormats.contains(inputType) {
            print("检测到 \(inputType) 格式不被 cwebp 支持，先转换为 JPEG 中间格式")
            
            // 创建临时 PNG 文件路径
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFileName = UUID().uuidString + ".jpeg"
            let tempJEPGURL = tempDirectory.appendingPathComponent(tempFileName)
            
            // 获取图片的原图
            guard let fullImage = image.loadImageIfCalculate() else {
                print("无法加载原始图片")
                return false
            }
            
            // 使用 Core Graphics 转换为 JPEG
            // 将 NSImage 转换为 CGImage
            guard let tiffData = fullImage.tiffRepresentation,
                  let source = CGImageSourceCreateWithData(tiffData as CFData, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                print("无法获取 CGImage")
                return false
            }
            
            // 创建 PNG 数据
            let outputData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                outputData,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            ) else {
                print("无法创建 CGImageDestination")
                return false
            }
            
            // 添加图像到目标
            CGImageDestinationAddImage(destination, cgImage, nil)
            
            guard CGImageDestinationFinalize(destination) else {
                print("图片转换失败")
                return false
            }
            
            // 获取压缩图片的 Data
            let compressedData = outputData as Data
            
            // 写入临时 JEPG 文件
            do {
                try compressedData.write(to: tempJEPGURL)
                print("成功创建临时 JPEG 文件:\(tempJEPGURL.path)")
                actualInputURL = tempJEPGURL
                needsCleanup = true
            } catch {
                print("写入临时 JPEG 文件失败:\(error.localizedDescription)")
                return false
            }
        }
        
        // 使用 cwebp 转换
        let quality = CompressionQuality.from(rate: appStorage.imageCompressionRate)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cwebp)
        
        // cwebp input.jpg -q 80 -o output.webp
        process.arguments = [
            actualInputURL.path,
            "-q", "\(quality.cwebp)",
            "-o", image.outputURL.path
        ]
        
        let result = await runProcess(process, for: image,engineName: "cwebp")
        
        // 清理临时文件
        if needsCleanup {
            do {
                try FileManager.default.removeItem(at: actualInputURL)
                print("已清理临时 JPEG 文件")
            } catch {
                print("清理临时文件失败")
            }
        }
        
        return result
    }
    
    // MARK: macOS 原生压缩
    private func compressWithNative(_ image: CustomImages) -> Bool {
        
        guard let fullImage = image.loadImageIfCalculate() else {
            return false
        }
        
        // 将 NSImage 转换为 CGImage
        guard let tiffData = fullImage.tiffRepresentation,
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
            print("图片写入成功，是否存在:\(FileManager.default.fileExists(atPath: image.outputURL.path))'")
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
    
    // 转换图片的方法，根据图片类型和配置选择合适的压缩引擎
    func conversionImage(_ image: CustomImages) async -> Bool {
        
        // 获取图片转换的大写格式
        let type = image.outputUppercased    // 大写文件后缀
        print("文件转换的大写格式:\(type)")
        
        // 根据配置和文件类型选择压缩引擎
        if appStorage.enableCwebp && type == "WEBP"{
            print("使用 Cwebp 引擎转换 WEBP 图片")
            return await compressWithCwebp(image)
        } else {
            print("使用 macOS 原生转换")
            return conversionWithCoreGraphics(image)
        }
    }
    
    // 使用 Core Graphics 转换图片
    func conversionWithCoreGraphics(_ image: CustomImages) -> Bool {
        
        guard let fullImage = image.loadImageIfCalculate() else {
            return false
        }
        
        // 获取CGImage
        guard let tiffData = fullImage.tiffRepresentation,
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
