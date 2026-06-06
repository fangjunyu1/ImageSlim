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
    @Published var saveName = "Select Location"

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
    
    // 是否完成评分
    @Published var didRequestReview = false { didSet { updateValue(key: "didRequestReview", newValue: didRequestReview, oldValue: oldValue)}}
    
    // 启用统计功能
    @Published var enableStatistics = false { didSet { updateValue(key: "enableStatistics", newValue: enableStatistics, oldValue: oldValue)}}
    
    // MARK: 统计功能
    
    // 已压缩图片数量
    @Published var imagesCompressed: Int64 = 0 { didSet { updateValue(key: "imagesCompressed", newValue: imagesCompressed, oldValue: oldValue)}}
    
    // 已转换图片数量
    @Published var imagesConverted: Int64 = 0 { didSet { updateValue(key: "imagesConverted", newValue: imagesConverted, oldValue: oldValue)}}
    
    // 已处理图片数量
    var totalImagesProcessed: Int64 {
        imagesCompressed + imagesConverted
    }
    
    // 原始图片总大小
    @Published var originalSize: Int64 = 0 { didSet { updateValue(key: "originalSize", newValue: originalSize, oldValue: oldValue)}}
    
    // 压缩后总大小
    @Published var compressedSize: Int64 = 0 { didSet { updateValue(key: "compressedSize", newValue: compressedSize, oldValue: oldValue)}}
    
    // 节省磁盘空间
    var diskSpaceSaved: Int64 {
        originalSize - compressedSize
    }
    
    // 平均压缩率
    var avgCompressionRatio: Double {
        guard originalSize > 0 else { return 0 }
        // 压缩后总大小 / 原始图片总大小
        return Double(compressedSize) / Double(originalSize)
    }
    
    // 平均压缩后大小
    var avgCompressedSize: Int64 {
        guard imagesCompressed > 0 else { return 0 }
        // 压缩后的大小 / 已压缩图片的数量
        return compressedSize / imagesCompressed
    }
    
    // 最大单张节省空间
    @Published var maxSizeSaved: Int64 = 0 { didSet { updateValue(key: "maxSizeSaved", newValue: maxSizeSaved, oldValue: oldValue)}}
    
    // 最大压缩率
    @Published var maxCompressionRatio: Double = 0.0 { didSet { updateValue(key: "maxCompressionRatio", newValue: maxCompressionRatio, oldValue: oldValue)}}
    
    // 最近一次处理时间
    @Published var lastProcessed: Date = Date.distantPast { didSet { updateValue(key: "lastProcessed", newValue: lastProcessed, oldValue: oldValue)}}
    
    // 首次使用时间
    @Published var firstUsed: Date = Date.distantPast { didSet { updateValue(key: "firstUsed", newValue: firstUsed, oldValue: oldValue)}}
    
    // 最近一次计算的累计使用时间
    @Published var lastDaysUsed:Date = Date.distantPast { didSet { updateValue(key: "lastDaysUsed", newValue: lastDaysUsed, oldValue: oldValue)}}
    
    // 累计使用天数
    @Published var daysUsed: Int = 0 { didSet { updateValue(key: "daysUsed", newValue: daysUsed, oldValue: oldValue)}}
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
            "convertTypeState": ConversionTypeState.jpeg.rawValue,    // 图片转换格式
            "enableStatistics": true    // 默认启用统计
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
        didRequestReview = UserDefaults.standard.bool(forKey: "didRequestReview") // 评分
        enableStatistics = UserDefaults.standard.bool(forKey: "enableStatistics") // 启用统计
        
        // 统计数据
        imagesCompressed = Int64(UserDefaults.standard.integer(forKey: "imagesCompressed")) // 已压缩图片数量
        imagesConverted = Int64(UserDefaults.standard.integer(forKey: "imagesConverted")) // 已转换图片数量
        originalSize = Int64(UserDefaults.standard.integer(forKey: "originalSize")) // 原始图片总大小
        compressedSize = Int64(UserDefaults.standard.integer(forKey: "compressedSize")) // 压缩后总大小
        maxSizeSaved = Int64(UserDefaults.standard.integer(forKey: "maxSizeSaved")) // 最大单张节省空间
        maxCompressionRatio = UserDefaults.standard.double(forKey: "maxCompressionRatio") // 最大压缩率
        daysUsed = UserDefaults.standard.integer(forKey: "daysUsed") // 累计使用天数
        
        // 日期类型 - 设置 nil
        //最近一次处理时间
        if defaults.object(forKey: "lastProcessed") == nil {
            lastProcessed = Date.distantPast
        } else {
            let timestamp = defaults.double(forKey: "lastProcessed")
            lastProcessed = Date(timeIntervalSince1970: timestamp)
        }
        
        // 首次使用时间
        if defaults.object(forKey: "firstUsed") == nil {
            firstUsed = Date.distantPast
        } else {
            let timestamp = defaults.double(forKey: "firstUsed")
            firstUsed = Date(timeIntervalSince1970: timestamp)
        }
        
        // 最近一次累计使用时间
        if defaults.object(forKey: "lastDaysUsed") == nil {
            lastDaysUsed = Date.distantPast
        } else {
            let timestamp = defaults.double(forKey: "lastDaysUsed")
            lastDaysUsed = Date(timeIntervalSince1970: timestamp)
        }
    }
}

// MARK: 更新字段，保存到 UserDefautls,并尝试同步 iCloud 数据
extension AppStorage {
    private func updateValue<T:Equatable>(key: String, newValue: T, oldValue: T) {
        guard newValue != oldValue, !isLoading else { return }
        
        let defaults = UserDefaults.standard
        let store = NSUbiquitousKeyValueStore.default
        
        // 处理 Date? 类型
        if let dateValue = newValue as? Date {
            let timestamp = dateValue.timeIntervalSince1970
            defaults.set(timestamp, forKey: key)
            store.set(timestamp, forKey: key)
        }
        // 处理其他类型
        else {
            defaults.set(newValue, forKey: key)
            store.set(newValue, forKey: key)
        }
        
        store.synchronize()
    }
}
