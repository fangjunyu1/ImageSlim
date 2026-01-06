//
//  ImageArrayViewModel.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/6.
//
//  管理应用压缩/转换的图片数组
//
import SwiftUI

class ImageArrayViewModel: ObservableObject {
    static let shared = ImageArrayViewModel()
    private init() {}
    
    // MARK: 压缩/转换配置
    // 非内购用户，限制 20 张图片
    @Published var limitImageNum = 20
    // 非内购用户，限制 5MB 图片
    @Published var limitImageSize = 5_000_000
    
    // MARK: 压缩/转换队列
    // 压缩图片数组
    @Published var compressedImages:[CustomImages] = []
    // 转换图片数组
    @Published var conversionImages:[CustomImages] = []
    // 任务队列：压缩图片数组
    @Published var compressTaskQueue: [CustomImages] = []
    // 任务队列：转换图片数组
    @Published var conversionTaskQueue: [CustomImages] = []
    
    // MARK: 压缩/转换队列状态
    // 当前有无被压缩的图片，isCompressing表示当前有图片被压缩，其他图片需要等待
    @Published var isCompressing = false
    // 当前有无被转换的图片，isCompressing = true，表示当前有图片被转换，其他图片需要等待
    @Published var isConversion = false
    
}
