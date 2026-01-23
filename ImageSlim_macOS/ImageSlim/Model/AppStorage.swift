//
//  AppStorageManager.swift.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import Foundation

@MainActor
class AppStorage:ObservableObject {
    
    static var shared = AppStorage()
    private init() {
        loadUserDefault()   // 加载 UserDefaults 中的数据
    }
    
    // 防止循环写入标志
    private var isLoading = false
    
    // 选择的视图
    @Published var selectedView:SelectedView = .compression
    // 默认选择保存文件夹的提示
    @Published var saveName = "Select Save Location"

    // 菜单栏显示图标，true为显示
    @Published var displayMenuBarIcon = true { didSet { updateValue(key: "displayMenuBarIcon", newValue: displayMenuBarIcon, oldValue: oldValue)}}
    
    // 启用第三方库压缩，当前使用pngquant压缩
    @Published var enablePngquant = false { didSet { updateValue(key: "enablePngquant", newValue: enablePngquant, oldValue: oldValue)}}
    
    // 启用第三方库压缩，当前使用Gifsicle压缩
    @Published var enableGifsicle = false { didSet { updateValue(key: "enableGifsicle", newValue: enableGifsicle, oldValue: oldValue)}}
    
    // 启用第三方库压缩，当前使用Cwebp压缩
    @Published var enableCwebp = false { didSet { updateValue(key: "enableCwebp", newValue: enableCwebp, oldValue: oldValue)}}
    
    // 图片压缩率
    @Published var imageCompressionRate = 0.0 { didSet { updateValue(key: "imageCompressionRate", newValue: imageCompressionRate, oldValue: oldValue)}}
    
    // 图片预览方式
    @Published var imagePreviewMode:PreviewMode = .quickLook { didSet { updateValue(key: "imagePreviewMode", newValue: imagePreviewMode.rawValue, oldValue: oldValue.rawValue)}}
    
    // 是否内购赞助
    @Published var inAppPurchaseMembership = false { didSet { updateValue(key: "inAppPurchaseMembership", newValue: inAppPurchaseMembership, oldValue: oldValue)}}
    
    // 保持原文件名
    @Published var keepOriginalFileName = false { didSet { updateValue(key: "keepOriginalFileName", newValue: keepOriginalFileName, oldValue: oldValue)}}
    
    // 启用图片转换
    @Published var EnableImageConversion = false { didSet { updateValue(key: "EnableImageConversion", newValue: EnableImageConversion, oldValue: oldValue)}}
    
    // 转换图片格式
    @Published var convertTypeState: ConversionTypeState = .jpeg { didSet { updateValue(key: "convertTypeState", newValue: convertTypeState.rawValue, oldValue: oldValue.rawValue)}}
}

// MARK: 从 UserDefaults 加载数据
extension AppStorage {
    // 从UserDefaults加载数据
    private func loadUserDefault() {
        isLoading = true    // 设置加载进度标志
        defer {
            isLoading = false
            print("退出UserDefaults同步")
        } // 还原加载进度标志
        let defaults = UserDefaults.standard
        // 注册默认值
        defaults.register(defaults: [
            "displayMenuBarIcon": true,   // 默认显示菜单栏图标
            "imageCompressionRate": 0,   // 默认压缩率为 0
            "imagePreviewMode": PreviewMode.quickLook.rawValue,  // 图片预览方式
            "EnableImageConversion": true,   // 默认启用图片转换
            "convertTypeState": ConversionTypeState.jpeg.rawValue    // 图片转换格式
        ])
        
        displayMenuBarIcon = defaults.bool(forKey: "displayMenuBarIcon")    // 显示图标
        enablePngquant = UserDefaults.standard.bool(forKey: "enablePngquant")   // 启用 pngquant
        enableGifsicle = UserDefaults.standard.bool(forKey: "enableGifsicle")   // 启用 gifsicle
        enableCwebp = UserDefaults.standard.bool(forKey: "enableCwebp")   // 启用 cwebp
        imageCompressionRate = UserDefaults.standard.double(forKey: "imageCompressionRate") //  图片压缩率
        let modeString = UserDefaults.standard.string(forKey: "imagePreviewMode") ?? "quickLook"
        imagePreviewMode = PreviewMode(rawValue: modeString) ?? PreviewMode.quickLook   // 图片预览方式
        inAppPurchaseMembership = UserDefaults.standard.bool(forKey: "inAppPurchaseMembership") // 内购标识
        keepOriginalFileName = UserDefaults.standard.bool(forKey: "keepOriginalFileName")   // 保持原文件名
        EnableImageConversion = UserDefaults.standard.bool(forKey: "EnableImageConversion") // 启用图片转换
        let formatsString = UserDefaults.standard.string(forKey: "convertTypeState") ?? "jpeg"
        convertTypeState = ConversionTypeState(rawValue: formatsString) ?? ConversionTypeState.jpeg
    }
}

// MARK: 更新字段，保存到 UserDefautls,并尝试同步 iCloud 数据
extension AppStorage {
    private func updateValue<T:Equatable>(key: String, newValue: T, oldValue: T) {
        guard newValue != oldValue, !isLoading else { return }
        
        // 同步保存到本地
        let defaults = UserDefaults.standard
        defaults.set(newValue, forKey: key)
        
        // iCloud
        let store = NSUbiquitousKeyValueStore.default
        store.set(newValue, forKey: key)
        store.synchronize()
    }
}
