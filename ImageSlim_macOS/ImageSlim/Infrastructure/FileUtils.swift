//
//  FileUtils.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/12/30.
//

import Foundation
import AppKit
import QuickLookUI
import SwiftUI
import Zip

@MainActor
enum FileUtils {
    
    // MARK: 将文件保存到临时文件夹
    // 用于将外部位置的图片存储到 Temporary 文件夹，并返回 URL
    static func saveURLToTempFile(fileURL: URL) -> URL? {
        let fileManager = FileManager.default
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileURL.lastPathComponent)
        
        // 如果目标已存在，删除旧的
        try? fileManager.removeItem(at: destinationURL)
        
        do {
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            return destinationURL
        } catch {
            print("复制失败: \(error)")
            return destinationURL
        }
    }
    
    // MARK: 保存图片并返回URL
    // 仅用于点击图片列表时，返回 URL 给 QuickLook 并预览图片。
    static func saveImageToTempFile(image: NSImage) -> URL? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        print("临时文件夹:\(FileManager.default.temporaryDirectory)")
        try? pngData.write(to: tempURL)
        return tempURL
    }
    
    // MARK: 询问用户选择保存目录，并保存图片/Zip
    static func askUserForSaveLocation(type: askUserForSaveLocationEnum) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        let saveDir = NSLocalizedString("Save location", comment: "选择保存文件夹")
        panel.prompt = saveDir
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let bookmark = try url.bookmarkData(options: [.withSecurityScope],includingResourceValuesForKeys: nil,
                                                    relativeTo: nil)
                UserDefaults.standard.set(bookmark, forKey: "SaveLocation")
                print("书签保存成功")
                
                if url.startAccessingSecurityScopedResource() {
                    switch type {
                    case .image(let image):
                        saveImg(file: image, url: url)
                    case .images(let ImagesURL, let showDownloadsProgress, let progress):
                        saveZip(ImagesURL: ImagesURL, url: url,showDownloadsProgress: showDownloadsProgress,progress: progress)
                    }
                    url.stopAccessingSecurityScopedResource()
                }
            } catch {
                print("书签创建失败: \(error)")
            }
        }
    }
    
    // MARK: 保存单张图片
    static func saveImg(file:CustomImages,url:URL) {
        // 获取文件名称，并拆分为 文件名+后缀名
        let nsName = file.name as NSString
        let fileName = nsName.deletingPathExtension    // 获取文件名称， test.zip 获取 test 等。
        let fileExt = nsName.pathExtension    // 获取文件扩展名， test.zip 获取 zip 等。
        
        // 设置最终名称，如果不保持原文件名称，则拼接_compress，保持原文件名称则显示正常的原文件名称
        let finalName: String
        if !AppStorage.shared.keepOriginalFileName {
            print("当前设置为不保持原文件名，因此添加_compress后缀")
            finalName = "\(fileName)_compress.\(fileExt)"
        } else {
            finalName = file.name
        }
        
        // 拼接 目录路径 + 文件名称
        let destinationURL = url.appendingPathComponent(finalName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: file.outputURL!, to: destinationURL)
        } catch {
            print("保存失败：\(error)")
        }
    }
    
    // MARK: 下载图片到文件夹
    static func saveToDownloads(file: CustomImages) {
        // 获取目录路径
        // 如果有安全书签，保存到安全书签的URL
        if let bookmark = UserDefaults.standard.data(forKey: "SaveLocation") {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if url.startAccessingSecurityScopedResource() {
                    saveImg(file: file,url: url)
                    url.stopAccessingSecurityScopedResource()
                } else {
                    print("无法访问资源")
                }
            } catch {
                print("解析书签失败: \(error)")
            }
        } else {
            // 如果没有保存过目录，让用户选择
            FileUtils.askUserForSaveLocation(type: .image(image: file))
        }
    }
    
    // MARK: 保存路径-安全书签
    static func createSaveLocation(saveName: Binding<String>) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        let saveDir = NSLocalizedString("Save location", comment: "选择保存文件夹")
        panel.prompt = saveDir
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(bookmark, forKey: "SaveLocation")
                print("书签保存成功")
                // 修改“保存图片文件夹”的名称，如果不修改名称，则容易被用户误认为保存图片文件夹没有选择成功
                refreshSaveName(saveName: saveName)
            } catch {
                print("书签创建失败: \(error)")
            }
        }
    }
    
    // MARK: 修改保存名称
    static func refreshSaveName(saveName: Binding<String>) {
        // 如果没有安全书签，保存目录默认为“选择保存目录”
        guard let saveLocation = UserDefaults.standard.data(forKey: "SaveLocation") else {
            saveName.wrappedValue = AppStorage.shared.saveName
            return
        }
        // 如果有安全书签，则获取图片保存目录的文件夹名称
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: saveLocation,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            saveName.wrappedValue = url.lastPathComponent
        } catch {
            print("解析书签失败: \(error)")
            saveName.wrappedValue = AppStorage.shared.saveName
        }
    }
}

// MARK: 其他一些方法
extension FileUtils {
    
    // 调用 Quick Look 预览图片
    static func previewImage(at url: URL) {
        guard let panel = QLPreviewPanel.shared() else { return }
        let dataSource = PreviewDataSource(urls: [url])
        panel.dataSource = dataSource
        panel.makeKeyAndOrderFront(nil)
    }
    
    // 发送邮件方法
    static func sendEmail() {
        let email = "fangjunyu.com@gmail.com"
        let subject = "ImageSlim"
        let body = "Hi fangjunyu,\n\n"
        
        // URL 编码参数
        let urlString = "mailto:\(email)?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if let url = URL(string: urlString ?? "") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // 计算文件的大小
    static func getFileSize(fileURL: URL) -> Int {
        // Finder上的图片大小
        // let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
        // let diskSize = resourceValues?.totalFileAllocatedSize ?? 0
        // print("Finder上的图片大小：\(diskSize)")
        
        // 获取文件的实际大小
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
        print("文件的实际大小：\(attributes ?? 0)")
        
        // 当macOS上有图像大小，以macOS上图像字节为准。
        // 如果macOS上没有图像大小，以获取的图像字节为准。
        
        // return diskSize > 0 ? diskSize : attributes ?? 0
        return attributes ?? 0
    }
    
    // 根据图片字节显示文本大小
    // 根据图片的字节大小显示适配的存储大小。
    static func TranslateSize(fileSize: Int) -> String {
        let num = 1000.0
        let size = Double(fileSize)
        
        if size < num {
            return "\(size) B"
        } else if size < pow(num,2.0) {
            let sizeNum = size / pow(num,1)
            return "\(ceil(sizeNum)) KB"
        } else if size < pow(num,3.0) {
            let sizeNum = size / pow(num,2)
            return "\(format(sizeNum)) MB"
        } else if size < pow(num,4.0) {
            let sizeNum = size / pow(num,3)
            return "\(format(sizeNum)) GB"
        } else if size < pow(num,5.0) {
            let sizeNum = size / pow(num,4)
            return "\(format(sizeNum)) TB"
        } else {
            let sizeNum = size / pow(num,5)
            return "\(format(sizeNum)) TB"
        }
        
        func format(_ value: Double) -> String {
            let roundedValue = (value * 10).rounded() / 10
            // 判断是否为整数
            if roundedValue.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f", roundedValue) // 无小数
            } else {
                return String(format: "%.1f", roundedValue) // 一位小数
            }
        }
    }
}

// MARK: Zip 相关代码
extension FileUtils {
    // Zip 压缩图片
    static func zipImages(isPurchase: Bool,limitImageSize: Int,keepOriginalFileName: Bool,images: [CustomImages],showDownloadsProgress:Binding<Bool>, progress: Binding<Double>) {
        Task {
            do {
                print("打包Zip")
                
                // 1、筛选图片输出 URL
                var ImagesURL:[URL] = images
                    .filter{ isPurchase || $0.inputSize < limitImageSize }
                    .compactMap { $0.outputURL }
                
                // 2、根据用户是否保持原文件名称选项，如果不保持原文件名称，则拼接_compress
                // 如果保持原文件名称，则不执行该代码
                if !keepOriginalFileName {
                    var tmpURL:[URL] = []
                    for url in ImagesURL {
                        let imageName = url.lastPathComponent   // 获取文件名称
                        let nsName = imageName as NSString
                        let fileName = nsName.deletingPathExtension    // 获取文件名称（无后缀）
                        let fileExt = nsName.pathExtension    // 获取文件扩展名（后缀）
                        let finalName: String = "\(fileName)_compress.\(fileExt)"   // 添加 _compress 后缀
                        let finalURL = url.deletingLastPathComponent().appendingPathComponent(finalName)    // 拼接完整URL
                        // 如果文件系统中有拼接的URL，则移除已有的 URL 文件
                        if FileManager.default.fileExists(atPath: finalURL.path) {
                            try FileManager.default.removeItem(at: finalURL)
                        }
                        // 将图片的输出 URL 复制到拼接_compress名称的 URL
                        try FileManager.default.copyItem(at: url, to: finalURL)
                        tmpURL.append(finalURL)
                    }
                    ImagesURL = tmpURL
                }
                
                // 3、判断 保存目录-安全书签，有的话，保存到安全书签的目录，没有的话，让用户手动选择目标
                // 如果有保存目录-安全书签
                if let saveLocation = UserDefaults.standard.data(forKey: "SaveLocation") {
                    var isStale = false
                    do {
                        let url = try URL(
                            resolvingBookmarkData: saveLocation,
                            options: [.withSecurityScope],
                            relativeTo: nil,
                            bookmarkDataIsStale: &isStale
                        )
                        if url.startAccessingSecurityScopedResource() {
                            // 调用 Zip 库，保存图片
                            saveZip(ImagesURL:ImagesURL, url: url,showDownloadsProgress: showDownloadsProgress,progress: progress)
                            url.stopAccessingSecurityScopedResource()
                        } else {
                            print("无法访问资源")
                        }
                    } catch {
                        print("解析书签失败: \(error)")
                    }
                    
                } else {
                    FileUtils.askUserForSaveLocation(type: .images(ImagesURL: ImagesURL, showDownloadsProgress: showDownloadsProgress, progress: progress))
                }
            } catch {
                showDownloadsProgress.wrappedValue = false
                print("打包失败")
            }
        }
    }
    
    // 保存 Zip 文件
    static func saveZip(ImagesURL:[URL], url: URL,showDownloadsProgress showDownloadsProgressBinding: Binding<Bool>,progress progressBinding: Binding<Double>){
        let calendar = Calendar.current
        let date = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        var destinationURL = URL(fileURLWithPath: "")
        if let year = components.year,
           let month = components.month,
           let day = components.day,
           let hour = components.hour,
           let minute = components.minute,
           let second = components.second {
            let iDay = day < 10 ? "0\(String(day))" : "\(day)"
            // 拼接 Zip 文件名称，添加年月日时分秒
            destinationURL =  url.appendingPathComponent("ImageSlim_\(year)-\(month)-\(iDay) \(hour).\(minute).\(second).zip")
        } else {
            // 如果无法解析日期，则保存为“ImageSlim.zip”
            destinationURL = url.appendingPathComponent("ImageSlim.zip")
        }
        do {
            progressBinding.wrappedValue = 0    // 重制打包进度
            showDownloadsProgressBinding.wrappedValue = true    // 显示打包进度
            // 调用 Zip 库保存图片
            try Zip.zipFiles(paths: ImagesURL, zipFilePath: destinationURL, password: nil) { progress in
                progressBinding.wrappedValue = progress // 更新打包进度
                if progress == 1 {
                    showDownloadsProgressBinding.wrappedValue = false   // 隐藏打包进度
                }
            }
            print("打包完成")
        } catch {
            showDownloadsProgressBinding.wrappedValue = false
            print("在SaveZip方法中崩溃")
        }
    }
}

enum askUserForSaveLocationEnum {
    case image(image:CustomImages)
    case images(ImagesURL:[URL],showDownloadsProgress:Binding<Bool>,progress: Binding<Double>)
}
