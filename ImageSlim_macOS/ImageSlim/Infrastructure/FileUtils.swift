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

enum FileUtils {
    
    // MARK: 询问用户选择保存目录，并保存图片/Zip
    @MainActor
    static func askUserForSaveLocation(type: askUserForSaveLocationEnum) -> Bool{
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
                    return false
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                switch type {
                case .image(let image):
                    return saveImg(file: image, url: url)
                case .images(let ImagesURL, let showDownloadsProgress, let progress):
                    return saveZip(
                        ImagesURL: ImagesURL,
                        url: url,
                        showDownloadsProgress: showDownloadsProgress,
                        progress: progress)
                }
            } catch {
                print("书签创建失败: \(error)")
                return false
            }
        }
        return false
    }
    
    // MARK: 保存单张图片
    @MainActor
    static func saveImg(file:CustomImages,url:URL) -> Bool {
        
        let fileName = file.name    // 获取文件名称， test.zip 获取 test 等。
        let fileExt = file.outputTypeLowercased    // 获取文件扩展名， test.zip 获取 zip 等。
        
        func makeName(index: Int) -> String {
            let suffix = index == 0 ? "" : "(\(index))"
            // 设置最终名称，如果不保持原文件名称，则拼接_compress，保持原文件名称则显示正常的原文件名称
            if AppStorage.shared.keepOriginalFileName {
                return "\(fileName)\(suffix).\(fileExt)"
            } else {
                return "\(fileName)_compress\(suffix).\(fileExt)"
            }
        }
        
        do {
            // 文件重复编码，默认为0，如果重复则进行叠加
            var index = 0
            // 拼接目录路径 + 文件名称
            var destinationURL: URL
            
            while true {
                destinationURL = url.appendingPathComponent(makeName(index: index))
                
                if !FileManager.default.fileExists(atPath: destinationURL.path) {
                    break   // 跳过本次循环
                }
                
                index += 1
                
                // 防止极端情况
                if index > 10_00 {
                    print("遍历发生报错")
                }
            }
            
            // 如果不存在同名文件，则复制并实现图片保存
            try FileManager.default.copyItem(at: file.outputURL, to: destinationURL)
            print("保存成功:\(destinationURL.lastPathComponent)")
            return true
        } catch {
            print("保存失败：\(error)")
            return false
        }
    }
    
    // MARK: 下载图片到文件夹
    @MainActor
    static func saveToDownloads(file: CustomImages) -> Bool {
        print("进入 saveToDownloads 方法")
        // 获取目录路径
        // 如果有安全书签，保存到安全书签的URL
        if let bookmark = UserDefaults.standard.data(forKey: "SaveLocation") {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    return saveImg(file: file,url: url)
                } else {
                    print("无法访问资源")
                    return false
                }
            } catch {
                print("解析书签失败: \(error)")
                return false
            }
        } else {
            // 如果没有保存过目录，让用户选择
            return FileUtils.askUserForSaveLocation(type: .image(image: file))
        }
    }
    
    // MARK: 保存路径-安全书签
    @MainActor
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
    @MainActor
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
        print("进入getFileSize，URL:\(fileURL)")
        print("文件是否存在:\(FileManager.default.fileExists(atPath: fileURL.path))")
        // Finder上的图片大小
        // let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
        // let diskSize = resourceValues?.totalFileAllocatedSize ?? 0
        // print("Finder上的图片大小：\(diskSize)")
        
        // 获取文件的实际大小
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
        
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
    @MainActor
    static func zipImages(isPurchase: Bool,limitImageSize: Int,keepOriginalFileName: Bool,images: [CustomImages],showDownloadsProgress:Binding<Bool>, progress: Binding<Double>) -> Bool {
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
                        defer {
                            url.stopAccessingSecurityScopedResource()
                        }
                        // 调用 Zip 库，保存图片
                        return saveZip(ImagesURL:ImagesURL, url: url,showDownloadsProgress: showDownloadsProgress,progress: progress)
                    } else {
                        print("无法访问资源")
                        return false
                    }
                } catch {
                    print("解析书签失败: \(error)")
                    return false
                }
            } else {
                return FileUtils.askUserForSaveLocation(type: .images(ImagesURL: ImagesURL, showDownloadsProgress: showDownloadsProgress, progress: progress))
            }
        } catch {
            showDownloadsProgress.wrappedValue = false
            print("打包失败")
            return false
        }
    }
    
    // 保存 Zip 文件
    static func saveZip(ImagesURL:[URL], url: URL,showDownloadsProgress showDownloadsProgressBinding: Binding<Bool>,progress progressBinding: Binding<Double>) -> Bool {
        
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
            return true
        } catch {
            showDownloadsProgressBinding.wrappedValue = false
            print("在SaveZip方法中崩溃")
            return false
        }
    }
}

enum askUserForSaveLocationEnum {
    case image(image:CustomImages)
    case images(ImagesURL:[URL],showDownloadsProgress:Binding<Bool>,progress: Binding<Double>)
}
