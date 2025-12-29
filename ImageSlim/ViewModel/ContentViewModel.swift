//
//  ContentViewModel.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/12/29.
//

import SwiftUI
import Zip

class ContentViewModel: ObservableObject {
    @StateObject var appStorage = AppStorage.shared
    @State var progress = 0.0
    @State var showDownloadsProgress = false
    
    private func saveImg(file:CustomImages,url:URL) {
        // 获取文件名称，并拆分为 文件名+后缀名
        let nsName = file.name as NSString
        let fileName = nsName.deletingPathExtension    // 获取文件名称， test.zip 获取 test 等。
        let fileExt = nsName.pathExtension    // 获取文件扩展名， test.zip 获取 zip 等。
        // 设置最终名称，如果不保持原文件名称，则拼接_compress，保持原文件名称则显示正常的原文件名称
        let finalName: String
        if !appStorage.keepOriginalFileName {
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
    
    private func saveZip(finalImagesURL:[URL], url: URL){
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
            destinationURL =  url.appendingPathComponent("ImageSlim_\(year)-\(month)-\(iDay) \(hour).\(minute).\(second).zip")
        } else {
            destinationURL = url.appendingPathComponent("ImageSlim.zip")
        }
        do {
            try Zip.zipFiles(paths: finalImagesURL, zipFilePath: destinationURL, password: nil) { progress in
                DispatchQueue.main.async {
                    self.progress = progress
                    if progress == 1 {
                        self.showDownloadsProgress = false
                    }
                }
            }
            DispatchQueue.main.async {
                print("打包完成")
            }
        } catch {
            DispatchQueue.main.async {
                self.showDownloadsProgress = false
                print("在SaveZip方法中崩溃")
            }
        }
    }
    
    func zipImages() {
        showDownloadsProgress = true
        progress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("打包Zip")
                
                // 1、获取需要打包的图片 URL
                print("开始整理需要打包的图片 URL")
                var images: [CustomImages] {
                    switch self.appStorage.selectedView {
                    case .compression:
                        return self.appStorage.images
                    case .conversion:
                        return self.appStorage.conversionImages
                    default:
                        return []
                    }
                }
                
                let ImagesURL:[URL] = images
                    .filter{ self.appStorage.inAppPurchaseMembership || $0.inputSize < 5_000_000 }
                    .compactMap { $0.outputURL }
                
                // 2、处理文件名，确定最终导出 URL
                print("创建 finalImagesURL 变量")
                var finalImagesURL:[URL] = []
                print("开始遍历图片数组")
                for url in ImagesURL {
                    // 获取文件名称
                    let imageName = url.lastPathComponent
                    
                    let nsName = imageName as NSString
                    let fileName = nsName.deletingPathExtension    // 获取文件名称
                    let fileExt = nsName.pathExtension    // 获取文件扩展名
                    // 设置最终名称，如果不保持原文件名称，则拼接_compress，保持原文件名称则显示正常的原文件名称
                    if !self.appStorage.keepOriginalFileName {
                        let finalName: String = "\(fileName)_compress.\(fileExt)"
                        let finalURL = url.deletingLastPathComponent().appendingPathComponent(finalName)
                        // 拼接 目录路径 + 文件名称
                        if FileManager.default.fileExists(atPath: finalURL.path) {
                            try FileManager.default.removeItem(at: finalURL)
                        }
                        print("copy前:url\(url),finalURL:\(finalURL)")
                        try FileManager.default.copyItem(at: url, to: finalURL)
                        print("copy后:url\(url),finalURL:\(finalURL)")
                        finalImagesURL.append(finalURL)
                        print("已添加文件：\(finalURL)")
                    } else {
                        print("保持原文件名，使用outputURL")
                        finalImagesURL.append(url)
                    }
                }
                
                // 3、判断 保存目录-安全书签，有的话，保存到安全书签的目录，没有的话，保存到Downloads目录
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
                            self.saveZip(finalImagesURL:finalImagesURL, url: url)
                            url.stopAccessingSecurityScopedResource()
                        } else {
                            print("无法访问资源")
                        }
                    } catch {
                        print("解析书签失败: \(error)")
                    }
                    
                } else {
                    self.askUserForSaveLocation(finalImagesURL: finalImagesURL)
                }
            } catch {
                DispatchQueue.main.async {
                    self.showDownloadsProgress = false
                    print("打包失败")
                }
            }
        }
    }
    
    /// 弹出 NSSavePanel 或 NSOpenPanel 让用户选择目录，并保存书签
    func askUserForSaveLocation(finalImagesURL: [URL]) {
        DispatchQueue.main.async {
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
                        self.saveZip(finalImagesURL: finalImagesURL, url: url)
                        url.stopAccessingSecurityScopedResource()
                    }
                } catch {
                    print("书签创建失败: \(error)")
                }
            }
        }
    }
}
