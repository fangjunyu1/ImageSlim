//
//  Image.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//

import SwiftUI

struct CustomImages {
    var id: UUID
    // 图片 NSImage数据
    var image: NSImage
    // 图片名称
    var name: String
    // 图片类型
    var type: String
    // 图片输入的大小
    var inputSize: Int
    // 图片输出的大小
    var outputSize: Int?
    // 图片实际压缩的比率
    var compressionRatio: Double?
    // 图片输出的位置
    var outputURL: URL?
    // 图片状态：.pending 等待压缩 .compressing 正在压缩 .completed 已压缩完成 .failed 压缩失败
    var compressionState:CompressionState
}
