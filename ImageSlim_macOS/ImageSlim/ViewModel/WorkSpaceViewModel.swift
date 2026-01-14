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

// 压缩任务
extension WorkSpaceViewModel {
    
    // 压缩图片的方法，根据图片类型和第三方库启用功能，实现对应图片格式的压缩
    func compressImage(_ image: CustomImages) async -> Bool {
        // 获取图片的大写格式
        let type = image.inputTypeUppercased    // 大写文件后缀
        if appStorage.enablePngquant && (type == "PNG" || type == "EXR" || type == "TIFF") {
            // 当前启用 Pngquant 并且图片格式为 PNG、EXR，使用 Pngquant 引擎压缩图片
            print("当前启用 Pngquant 并且图片格式为 PNG、EXR、TIFF，使用 Pngquant 引擎压缩图片")
            return await compressWithPngquant(image)
        } else if appStorage.enableGifsicle && type == "GIF" {
            print("当前启用 Gifsicle 并且图片格式为 GIF，使用 Gifsicle 引擎压缩图片")
            // 当前启用 Gifsicle 并且图片格式为 GIF，使用 Gifsicle 引擎压缩图片
            return await compressWithGifsicle(image)
        } else {
            // 默认 macOS 原生压缩
            print("使用 macOS 默认压缩")
            return compressWithNative(image)
        }
    }
    
    // 压缩场景1、使用 Pngquant 压缩图片
    private func compressWithPngquant(_ image: CustomImages) async -> Bool {
        
        print("当前已启用 Pngquant 引擎，压缩 PNG、EXR、TIFF 图片")
        guard let pngquant = Bundle.main.path(forResource: "pngquant", ofType: nil) else {
            print("pngquant not found in app bundle.")
            return false
        }
        
        let quality = getPngquantQualityString()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: pngquant)
        // pngquant --quality=65-80 --output "/Users/fangjunyu/Desktop/IMG_3104_compressed.png" "/Users/fangjunyu/Desktop/IMG_3104.PNG"
        process.arguments = [
            "--quality=\(quality)",
            "--force",
            "--output",
            image.outputURL.path,
            image.inputURL.path]
        
        return await runProcess(process: process, image: image)
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
    
    // 压缩场景2、使用 Gifsicle 压缩图片
    private func compressWithGifsicle(_ image: CustomImages) async -> Bool {
        
        print("当前已启用 Gifsicle 引擎，压缩 Gif 图片")
        guard let gifsicle = Bundle.main.path(forResource: "gifsicle", ofType: nil) else {
            print("gifsicle not found in app bundle.")
            return false
        }
        
        let quality = getGifsicleQualityString()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gifsicle)
        // gifsicle -O3 --colors 256 input.gif -o output.gif
        process.arguments = [
            "--optimize=3",
            "--colors", "\(quality)",
            image.inputURL.path,
            "--output",
            image.outputURL.path]
        
        return await runProcess(process: process, image: image)
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
    
    // 压缩场景3、使用 NSbitmapimagerep 压缩图片
    private func compressWithNative(_ image: CustomImages) -> Bool {
        
        // MARK: macOS原生压缩类CGImageDestination的变量
        // 将 NSImage 转换为 CGImage
        guard let tiffData = image.image?.tiffRepresentation,
              let source = CGImageSourceCreateWithData(tiffData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return false
        }
        
        // 设置压缩格式
        var imageType: CFString {
            switch image.inputType.uppercased() {
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
                // 所有不支持的类型强制转换为 PNG 再压缩
                return UTType.png.identifier as CFString
            }
        }
        
        // MARK: 不启用第三方库时，使用 MacOS 原生 CGImageDestination 压缩图片
        // 创建用于接收压缩后数据的容器
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(outputData, imageType, 1, nil) else {
            return false
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
            
            // 如果压缩后的图片大于压缩图片原始大写
            // 使用原始 tiffData 或原始文件数据替代
            if imageData.count > image.inputSize {
                print("压缩结果比原图大，保留原图")
                print("图片路径:\(image.outputURL)")
                return true
            }
            
            do {
                // 将压缩图片的 Data，写入临时文件
                try imageData.write(to: image.outputURL)
                print("图片路径:\(image.outputURL)")
                return true
            } catch {
                print("数据写入失败")
                return false
            }
        } else {
            print("图片写入路径失败")
            return false
        }
    }
    
    // 运行程序
    nonisolated private func runProcess(process:Process,image:CustomImages) async -> Bool {
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let fileHandle = pipe.fileHandleForReading
        
        do {
            try process.run()   // 启动
            return await withCheckedContinuation { const in
                process.terminationHandler = { process in
                    let logData = fileHandle.readDataToEndOfFile()
                    if let log = String(data: logData, encoding: .utf8) {
                        print("pngquant 日志：\n\(log)")
                    }
                    // 更新 Image 图片的输出大小，输出路径以及计算压缩比率
                    if process.terminationStatus == 0 {
                        print("压缩完成")
                        const.resume(returning: true)
                    } else if process.terminationStatus == 99 {
                        print("压缩后和原图一致，返回码 99")
                        const.resume(returning: false)
                    } else {
                        print("压缩失败，退出码：\(process.terminationStatus)")
                        const.resume(returning: false)
                    }
                }
            }
        } catch {
            print("运行 pngquant 失败：\(error)")
            return false
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
    nonisolated func conversionImage(_ image: CustomImages) -> Bool {
        
        // MARK: macOS 原生转换类 Core Graphics
        // 获取CGImage
        guard let tiffData = image.image?.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let cgImage = bitmap.cgImage else {
            print("无法获取 CGImage")
            return false
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
            case .pdf:
                id = UTType.pdf.identifier
            case .webp:
                id = UTType.webP.identifier
            }
            return id as CFString
        }
        
        // Step 4: 创建 CGImageDestination
        guard let destination = CGImageDestinationCreateWithData(outputData, uttypeID, 1, nil) else {
            print("无法创建 CGImageDestination")
            return false
        }
        
        // Step 5: 设置压缩参数
        let options: CFDictionary = [:] as CFDictionary
        
        // Step 6: 添加图像并写入
        CGImageDestinationAddImage(destination, cgImage, options)
        CGImageDestinationFinalize(destination)
        
        let imageData = outputData as Data
        do {
            // 将转换图片的 Data，写入临时文件
            try imageData.write(to: image.outputURL)
            return true
        } catch {
            print("数据写入失败")
            return false
        }
    }
}
