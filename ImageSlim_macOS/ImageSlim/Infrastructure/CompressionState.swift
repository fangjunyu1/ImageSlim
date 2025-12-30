//
//  CompressionState.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/11.
//
// 压缩状态

enum CompressionState {
    case pending     // 等待压缩
    case compressing // 正在压缩
    case completed   // 已压缩完成
    case failed      // 压缩失败
}
