//
//  ShareViewController.swift
//  ImageSlimShare
//
//  Created by 方君宇 on 2026/1/27.
//

import Cocoa

class ShareViewController: NSViewController {
    
    override var nibName: NSNib.Name? {
        return nil
    }
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // 调用共享代码
        processSharedContent()
    }
    
    private func processSharedContent() {
        // 第一步：从 extensionContext 获取共享的文件
        guard let extensionContext = self.extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem],
              let extensionItem = inputItems.first,
              let attachments = extensionItem.attachments else {
            print("没有共享内容")
            close()
            return
        }
        
        let fileProviders = attachments.filter {
            // 检测 provider 是否提供文件URL
            $0.hasItemConformingToTypeIdentifier("public.file-url")
        }
        
        let group = DispatchGroup()
        
        for itemProvider in fileProviders {
            group.enter()
            itemProvider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { [weak self] (secureCoding, error) in
                defer { group.leave() }
                
                DispatchQueue.main.async {
                    if let url = secureCoding as? URL {
                        self?.handleImageFile(url)
                    } else if let data = secureCoding as? Data,
                              let urlString = String(data: data, encoding: .utf8),
                              let url = URL(string: urlString) {
                        self?.handleImageFile(url)
                    }
                }
            }
            
        }
        
        // 等待所有文件处理完毕
        group.notify(queue: .main) { [weak self] in
            self?.openMainApp()
            self?.close()
        }
    }
    
    private func handleImageFile(_ url: URL) {
        // App Group 名称
        let appGroupIdentifier = "group.com.fangjunyu.ImageSlim"
        // 共享文件夹路径
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
        // 共享图片的临时目录
        let sharedDir = containerURL.appendingPathComponent("SharedImages", isDirectory: true)
        // 文件在共享目录中的路径（使用 UUID + 文件名的格式）
        let destinationURL = sharedDir.appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)

         // 尝试创建临时目录（如果不存在）
        try? FileManager.default.createDirectory(at: sharedDir, withIntermediateDirectories: true)

        // 将文件写入目标目录
        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
            print("文件已保存到共享目录: \(destinationURL.path)")
        } catch {
            print("文件 \(url) 写入失败: \(error.localizedDescription)")
        }
    }

    private func openMainApp() {
        // URL Scheme，需要在主 App 的 Info.plist 中配置
        let urlScheme = "ImageSlim://open-shared-images"
        
        if let url = URL(string: urlScheme) {
            // macOS 使用 NSWorkspace 打开 URL
            NSWorkspace.shared.open(url)
        }
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
