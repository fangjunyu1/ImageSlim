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
        if appStorage.inAppPurchaseMembership {
            // 支持 PNG, JPEG, WEBP 等多种格式。
            Text("Supports PNG, JPEG, WEBP, etc.")
                .font(.footnote)
                .foregroundColor(.gray)
        } else {
            // 最多选择 20 张图片，每张大小不超过 5MB。
            Text("Select up to 20 images, up to 5 MB each.")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
}
