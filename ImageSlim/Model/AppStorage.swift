//
//  AppStorageManager.swift.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import Foundation

class AppStorage:ObservableObject {
    static var shared = AppStorage()
    private init() {
        loadUserDefault()   // 加载 UserDefaults 中的数据
    }
    
    // 菜单栏显示图标，true为显示
    @Published var displayMenuBarIcon = true {
        willSet {
            // 修改 USerDefault 中的值
            UserDefaults.standard.set(newValue, forKey: "displayMenuBarIcon")
            // 修改 iCloud 中的值
            let store = NSUbiquitousKeyValueStore.default
            store.set(newValue, forKey: "displayMenuBarIcon")
            store.synchronize() // 强制触发数据同步
        }
    }
    
    // 图片压缩率
    @Published var imageCompressionRate = 0.6 {
        willSet {
            // 修改 USerDefault 中的值
            UserDefaults.standard.set(newValue, forKey: "imageCompressionRate")
            // 修改 iCloud 中的值
            let store = NSUbiquitousKeyValueStore.default
            store.set(newValue, forKey: "imageCompressionRate")
            store.synchronize() // 强制触发数据同步
        }
    }
    
    // 图片预览方式
    @Published var imagePreviewMode:PreviewMode = .quickLook {
        willSet {
            // 修改 USerDefault 中的值
            print("newValue type:\(type(of:newValue))")
            UserDefaults.standard.set(newValue.rawValue, forKey: "imagePreviewMode")
            // 修改 iCloud 中的值
            let store = NSUbiquitousKeyValueStore.default
            store.set(newValue.rawValue, forKey: "imagePreviewMode")
            store.synchronize() // 强制触发数据同步
        }
    }
    
    // 从UserDefaults加载数据
    private func loadUserDefault() {
        
        // 如果 UserDefaults 中没有 displayMenuBarIcon 键，设置默认值为 true
        if UserDefaults.standard.object(forKey: "displayMenuBarIcon") == nil {
            // 设置默认值为 true
            UserDefaults.standard.set(true, forKey: "displayMenuBarIcon")
            displayMenuBarIcon = true  // 菜单栏图标
        } else {
            displayMenuBarIcon = UserDefaults.standard.bool(forKey: "displayMenuBarIcon")
        }
        
        // 如果 UserDefaults 中没有 imageCompressionRate 键，设置默认为 0.6
        if UserDefaults.standard.object(forKey: "imageCompressionRate") == nil {
            // 设置默认值为 true
            UserDefaults.standard.set(0.6, forKey: "imageCompressionRate")
            imageCompressionRate = 0.6  // 菜单栏图标
        } else {
            imageCompressionRate = UserDefaults.standard.double(forKey: "imageCompressionRate")
        }
        
        // 如果 UserDefaults 中没有 imagePreviewMode 键，设置默认为 Quick Look
        if UserDefaults.standard.object(forKey: "imagePreviewMode") == nil {
            // 设置默认值为 true
            UserDefaults.standard.set(PreviewMode.quickLook.rawValue, forKey: "imagePreviewMode")
            imagePreviewMode = PreviewMode.quickLook  // 菜单栏图标
        } else {
            let modeString = UserDefaults.standard.object(forKey: "imagePreviewMode") as? String ?? "quickLook"
            let mode = PreviewMode(rawValue: modeString)
            imagePreviewMode = mode ?? PreviewMode.quickLook
        }
    }
}
