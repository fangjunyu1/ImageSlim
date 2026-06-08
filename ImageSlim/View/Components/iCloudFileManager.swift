//
//  iCloudFileManager.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/6/8.
//

import Foundation

final class iCloudFileManager {
    static let shared = iCloudFileManager()

    private init() {}
    
    /// 判断是否存在对应的图片占位符文件
    func isContainImagePlaceholder(fileName: String) -> Bool {
        // 获取 iCloud 目录 URL
        guard let documentsURL = iCloudDocumentsURL() else {
            return false
        }
        
        let fileURL = documentsURL.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return true
        } else {
            return false
        }
    }
    
    /// 获取 iCloud Documents 目录
    func iCloudDocumentsURL() -> URL? {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            return nil
        }

        let documentsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)

        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            try? FileManager.default.createDirectory(
                at: documentsURL,
                withIntermediateDirectories: true
            )
        }

        return documentsURL
    }

    /// 保存文件到 iCloud
    func save(data: Data, fileName: String) throws {
        guard let documentsURL = iCloudDocumentsURL() else {
            throw NSError(
                domain: "iCloud",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "iCloud is not available."]
            )
        }

        let fileURL = documentsURL.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
    }

    /// 读取 iCloud 文件
    func read(fileName: String) throws -> Data {
        guard let documentsURL = iCloudDocumentsURL() else {
            throw NSError(
                domain: "iCloud",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "iCloud is not available."]
            )
        }

        let fileURL = documentsURL.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return try Data(contentsOf: fileURL)
        } else {
            throw NSError(
                domain: "iCloud",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "File not found."]
            )
        }
    }
    
    // 清理 iCloud 文件
    func clear(fileName: String) {
        guard let documentsURL = iCloudDocumentsURL() else {
            print("iCloud 文档目录获取失败")
            return
        }

        let fileURL = documentsURL.appendingPathComponent(fileName)

        do {
            try FileManager.default.removeItem(at: fileURL)
            print("文件删除成功")
        } catch {
            print("删除文件失败或未找到对应文件: \(error)")
        }
    }
}
