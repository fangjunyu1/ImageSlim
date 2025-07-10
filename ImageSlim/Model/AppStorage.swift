//
//  AppStorageManager.swift.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import Foundation

class AppStorage:ObservableObject {
    static var shared = AppStorage()
    // 菜单栏显示图标，true为显示
    @Published var displayMenuBarIcon = true
    // 图片压缩率
    @Published var imageCompressionRate = 0.0
    // 图片预览方式
    @Published var imagePreviewMode:PreviewMode = .quickLook
}

enum PreviewMode {
    case window
    case quickLook
}
