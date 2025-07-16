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
    
    // 选择的视图
    @Published var selectedView:SelectedView = .compression
    
    // 非内购用户，限制 20 张图片
    @Published var limitImageNum = 20
    
    // 存储图片
    @Published var images:[CustomImages] = []
    
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
    
    // 启用第三方库压缩，当前使用pngquant压缩
    @Published var enableThirdPartyLibraries = false {
        willSet {
            // 修改 USerDefault 中的值
            UserDefaults.standard.set(newValue, forKey: "enableThirdPartyLibraries")
            // 修改 iCloud 中的值
            let store = NSUbiquitousKeyValueStore.default
            store.set(newValue, forKey: "enableThirdPartyLibraries")
            store.synchronize() // 强制触发数据同步
        }
    }
    
    // 图片压缩率
    @Published var imageCompressionRate = 0.0 {
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
            UserDefaults.standard.set(newValue.rawValue, forKey: "imagePreviewMode")
            // 修改 iCloud 中的值
            let store = NSUbiquitousKeyValueStore.default
            store.set(newValue.rawValue, forKey: "imagePreviewMode")
            store.synchronize() // 强制触发数据同步
        }
    }
    
    // 图片保存目录
    @Published var imageSaveDirectory: SaveDirectory = .downloadsDirectory {
        willSet {
            // 修改 USerDefault 中的值
            UserDefaults.standard.set(imageSaveDirectory.rawValue, forKey: "imageSaveDirectory")
            // 修改 iCloud 中的值
            let store = NSUbiquitousKeyValueStore.default
            store.set(newValue.rawValue, forKey: "imageSaveDirectory")
            store.synchronize() // 强制触发数据同步
        }
    }
    
    // 是否内购赞助
    @Published var inAppPurchaseMembership = false {
        willSet {
            // 修改 USerDefault 中的值
            UserDefaults.standard.set(newValue, forKey: "inAppPurchaseMembership")
            // 修改 iCloud 中的值
            let store = NSUbiquitousKeyValueStore.default
            store.set(newValue, forKey: "inAppPurchaseMembership")
            store.synchronize() // 强制触发数据同步
        }
    }
    
    // 从UserDefaults加载数据
    private func loadUserDefault() {
        
        // 1、是否启用菜单栏显示图标
        // 如果 UserDefaults 中没有 displayMenuBarIcon 键，设置默认值为 true
        if UserDefaults.standard.object(forKey: "displayMenuBarIcon") == nil {
            // 设置默认值为 true
            print("菜单栏显示图标，默认值为 nil，设置为 true")
            UserDefaults.standard.set(true, forKey: "displayMenuBarIcon")
            displayMenuBarIcon = true  // 菜单栏图标
        } else {
            displayMenuBarIcon = UserDefaults.standard.bool(forKey: "displayMenuBarIcon")
            print("菜单栏显示图标，默认值为 \(displayMenuBarIcon)")
        }
        
        // 2、启用第三方库压缩
        // 如果 UserDefaults 中没有 displayMenuBarIcon 键，设置默认值为 true
        if UserDefaults.standard.object(forKey: "enableThirdPartyLibraries") == nil {
            // 设置默认值为 true
            print("菜单栏显示图标，默认值为 nil，设置为 false")
            UserDefaults.standard.set(false, forKey: "enableThirdPartyLibraries")
            enableThirdPartyLibraries = false  // 菜单栏图标
        } else {
            enableThirdPartyLibraries = UserDefaults.standard.bool(forKey: "enableThirdPartyLibraries")
            print("菜单栏显示图标，默认值为 \(enableThirdPartyLibraries)")
        }
        
        // 3、图片压缩率
        // 如果 UserDefaults 中没有 imageCompressionRate 键，设置默认为 0.0
        if UserDefaults.standard.object(forKey: "imageCompressionRate") == nil {
            // 设置默认值为 true
            print("图片压缩率，默认值为 nil，设置为 0.0")
            UserDefaults.standard.set(0.0, forKey: "imageCompressionRate")
            imageCompressionRate = 0.0  // 菜单栏图标
        } else {
            imageCompressionRate = UserDefaults.standard.double(forKey: "imageCompressionRate")
            print("图片压缩率，默认值为 \(imageCompressionRate)")
        }
        
        // 4、图片预览方式
        // 如果 UserDefaults 中没有 imagePreviewMode 键，设置默认为 Quick Look
        if UserDefaults.standard.object(forKey: "imagePreviewMode") == nil {
            // 设置默认值为 true
            print("图片预览方式，默认值为 nil，设置为 PreviewMode.quickLook")
            UserDefaults.standard.set(PreviewMode.quickLook.rawValue, forKey: "imagePreviewMode")
            imagePreviewMode = PreviewMode.quickLook  // 菜单栏图标
        } else {
            let modeString = UserDefaults.standard.object(forKey: "imagePreviewMode") as? String ?? "quickLook"
            let mode = PreviewMode(rawValue: modeString)
            imagePreviewMode = mode ?? PreviewMode.quickLook
            print("图片预览方式，默认值为 \(imagePreviewMode)")
        }
        
        // 5、图片保存目录【同步UserDefaults】
        // 如果 UserDefaults 中没有 imageSaveDirectory 键，设置默认为 DownloadsDirectory
        if UserDefaults.standard.object(forKey: "imageSaveDirectory") == nil {
            // 设置默认值为 true
            print("图片保存目录，默认值为 nil，设置为 SaveDirectory.downloadsDirectory")
            UserDefaults.standard.set(SaveDirectory.downloadsDirectory.rawValue, forKey: "imagePreviewMode")
            imageSaveDirectory = SaveDirectory.downloadsDirectory  // 菜单栏图标
        } else {
            let directoryString = UserDefaults.standard.object(forKey: "imageSaveDirectory") as? String ?? "downloadsDirectory"
            let directory = SaveDirectory(rawValue: directoryString)
            imageSaveDirectory = directory ?? SaveDirectory.downloadsDirectory
            print("图片保存目录，默认值为 \(imageSaveDirectory)")
        }
        
        // 6、应用赞助标识
        // 如果 UserDefaults 中没有 inAppPurchaseMembership 键，设置默认为 false
        if UserDefaults.standard.object(forKey: "inAppPurchaseMembership") == nil {
            // 设置默认值为 true
            print("应用赞助，默认值为nil，设置为 false")
            UserDefaults.standard.set(false, forKey: "inAppPurchaseMembership")
            inAppPurchaseMembership = false  // 菜单栏图标
        } else {
            // 如果 UserDefaults 有 inAppPurchaseMembership 键，则设置为对应 Bool 值
            inAppPurchaseMembership = UserDefaults.standard.bool(forKey: "inAppPurchaseMembership")
            print("应用赞助，默认值为 \(inAppPurchaseMembership)")
        }
    }
}
