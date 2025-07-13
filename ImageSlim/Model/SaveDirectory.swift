//
//  SaveDirectory.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/13.
//

enum SaveDirectory:String, CaseIterable, Hashable, Identifiable {
    var id: String { rawValue }
    
    case downloadsDirectory  // 下载目录
    // case sharedPublicDirectory  // 公共目录，没有权限，需要安全书签授权，以后再优化
    // case desktopDirectory  // 桌面目录，没有权限，需要安全书签授权，以后再优化
    // case documentDirectory  // 应用自己的文档目录，不是用户文档目录
    case picturesDirectory  // 图片目录
}
