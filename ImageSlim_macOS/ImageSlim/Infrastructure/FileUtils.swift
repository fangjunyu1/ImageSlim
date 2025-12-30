//
//  FileUtils.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/12/30.
//

import Foundation
import AppKit

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
    
}
