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
    @Published var completeCompression = false  // 完成压缩，false为未完成，true为完成
    @Published var selectedView:SelectedView = .compression
    @Published var images:[CustomImages] = [] {
        didSet {
            if images.isEmpty {
                completeCompression = false
            } else {
                completeCompression = true
            }
        }
    }
}

enum SelectedView {
    case compression
    case settings
}
