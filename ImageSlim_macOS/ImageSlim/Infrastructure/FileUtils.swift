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

@MainActor
struct FileUtils {
    
    // MARK: 计算文件的大小
    static func getFileSize(fileURL: URL) -> Int {
        // Finder上的图片大小
        //        let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
        //        let diskSize = resourceValues?.totalFileAllocatedSize ?? 0
        //        print("Finder上的图片大小：\(diskSize)")
        
        // 获取文件的实际大小
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
        print("文件的实际大小：\(attributes ?? 0)")
        
        // 当macOS上有图像大小，以macOS上图像字节为准。
        // 如果macOS上没有图像大小，以获取的图像字节为准。
        
        // return diskSize > 0 ? diskSize : attributes ?? 0
        return attributes ?? 0
    }
    
    // MARK: 将文件保存到临时文件夹
    // 将图片存储到照片并返回URL,将临时文件路径存储到 Temporary 文件夹，并返回 URL
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
    // 将图片存储到照片并返回URL
    static func saveImageToTempFile(image: NSImage) -> URL? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        try? pngData.write(to: tempURL)
        return tempURL
    }
    
    // MARK: 根据图片字节显示文本大小
    // 根据图片的字节大小显示适配的存储大小。
    static func TranslateSize(fileSize: Int) -> String {
        let num = 1000.0
        let size = Double(fileSize)
        
        func format(_ value: Double) -> String {
            let roundedValue = (value * 10).rounded() / 10
            // 判断是否为整数
            print("1、roundedValue:\(roundedValue)")
            if roundedValue.truncatingRemainder(dividingBy: 1) == 0 {
                print("2、roundedValue:\(roundedValue)")
                return String(format: "%.0f", roundedValue) // 无小数
            } else {
                print("2、roundedValue:\(roundedValue)")
                return String(format: "%.1f", roundedValue) // 一位小数
            }
        }
        
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
    }
    
    // MARK: 保存目录
    /// 弹出 NSSavePanel 或 NSOpenPanel 让用户选择目录，并保存书签
    static func askUserForSaveLocation(file: CustomImages) {
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
                    saveImg(file: file, url: url)
                    url.stopAccessingSecurityScopedResource()
                }
            } catch {
                print("书签创建失败: \(error)")
            }
        }
    }
    
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
    
    // MARK: 调用 Quick Look 预览图片
    static func previewImage(at url: URL) {
        guard let panel = QLPreviewPanel.shared() else { return }
        let dataSource = PreviewDataSource(urls: [url])
        panel.dataSource = dataSource
        panel.makeKeyAndOrderFront(nil)
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
                        FileUtils.saveImg(file: file,url: url)
                        url.stopAccessingSecurityScopedResource()
                    } else {
                        print("无法访问资源")
                    }
                } catch {
                    print("解析书签失败: \(error)")
                }
        } else {
            // 如果没有保存过目录，让用户选择
            FileUtils.askUserForSaveLocation(file: file)
        }
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
                refreshSaveName(saveName: saveName)
            } catch {
                print("书签创建失败: \(error)")
            }
        }
    }
    
    
    // MARK: 重试保存名称
    static func refreshSaveName(saveName: Binding<String>) {
        guard let saveLocation = UserDefaults.standard.data(forKey: "SaveLocation") else {
            saveName.wrappedValue = "Select Save Location"
            return
        }
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
            saveName.wrappedValue = "Select Save Location"
        }
    }
}
