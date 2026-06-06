//
//  ImagePreviewWindow.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//

import AppKit
import SwiftUI

class ImagePreviewWindow {
    
    static let shared = ImagePreviewWindow()
    
    private var window: NSWindow?
    private var imageView: NSImageView?
    
    private init() {}   // 防止外部初始化
    
    func show(image: NSImage) {
        
        // 1、如果窗口不存则，先创建
        if window == nil {
            createWindow()
        }
        
        // 2、更新内容视图
        updateContent(with: image)
        imageView?.image = image
        
        // 3、显示窗口并置前
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createWindow() {
        
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // 5、设置窗口属性
        window.title = "Image Preview"
        window.minSize = NSSize(width: 400, height: 400)
        window.minSize = NSSize(width: 1000, height: 1000)
        window.isReleasedWhenClosed = false
        window.center()
        
        
        self.window = window
    }
    
    private func updateContent(with image: NSImage) {
        guard let window = window else { return }
        
        // 创建 SwiftUI 视图
        let contentView = ImagePreviewView(image: image)
        
        // 使用 NSHostingController 桥接
        let hostingViewController = NSHostingController(rootView: contentView)
        
        // 设置为窗口的内容控制器
        window.contentViewController = hostingViewController
    }
}

struct ImagePreviewView: View {
    var image: NSImage
    var body: some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(minWidth: 400, minHeight: 400)
            .padding()
    }
}
