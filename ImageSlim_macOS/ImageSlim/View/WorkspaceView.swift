//
//  WorkspaceView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import SwiftUI

struct WorkspaceView: View {
    @EnvironmentObject var appStorage: AppStorage
    var body: some View {
        if appStorage.selectedView == .compression {
            CompressionView()
        } else if appStorage.selectedView == .settings {
            SettingsView()
        } else if appStorage.selectedView == .sponsorUs {
            SponsorUsView()
        } else if appStorage.selectedView == .conversion {
            ConversionView()
        }
    }
}

#Preview {
    WorkspaceView()
        .environmentObject(AppStorage.shared)
        // .environment(\.locale, .init(identifier: "ml")) // 设置为马拉雅拉姆语
}
