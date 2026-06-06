//
//  CompressionState.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/11.
//
// 压缩状态

enum TaskState {
    case pending     // 等待
    case running     // 正在处理
    case completed   // 处理完成
    case failed      // 失败
}

enum DownloadState {
    case idle   // 尚未开始
    case running    // 下载中
    case complete   // 已完成
    case failed     // 失败
}
