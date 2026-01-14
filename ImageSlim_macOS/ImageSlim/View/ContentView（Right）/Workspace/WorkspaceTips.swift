//
//  WorkspaceTips.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/2.
//

import SwiftUI

struct WorkspaceTips: View {
    @EnvironmentObject var appStorage: AppStorage
    var type: WorkTaskType
    var body: some View {
        switch type {
            // 压缩提示
        case .compression:
            if appStorage.inAppPurchaseMembership {
                // 支持 .png, .jpeg, .bmp, .tiff 等各种格式。
                Text("Supports multiple formats including .png, .jpeg, .bmp, .tiff, etc.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            } else {
                // 最多选择 20 张图片，每张大小不超过 5MB。
                Text("Select up to 20 pictures, each no larger than 5MB.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            // 转换提示
        case .conversion:
            if appStorage.inAppPurchaseMembership {
                Text("Supports multiple formats including .png, .jpeg, .bmp, .tiff, etc.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            } else {
                Text("Select up to 20 pictures, each no larger than 5MB.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
    }
}
