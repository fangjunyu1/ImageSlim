//
//  TemporaryData.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import Foundation

class TemporaryData: ObservableObject {
    static var shared = TemporaryData()
    private init() {}
    @Published var displayImageQueue = false    // 上传图片后，显示图片队列
    @Published var completeCompression = false  // 完成压缩，false为未完成，true为完成
    @Published var selectedView:SelectedView = .compression
}

enum SelectedView {
    case compression
    case settings
}
