//
//  SaveDirectory.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/13.
//

enum SaveDirectory:String, CaseIterable, Hashable, Identifiable {
    var id: String { rawValue }
    
    case downloadsDirectory  // 下载目录
    case sharedPublicDirectory  // 公共目录
    case desktopDirectory  // 桌面目录
    case documentDirectory  // 文档目录
    case picturesDirectory  // 图片目录
}
