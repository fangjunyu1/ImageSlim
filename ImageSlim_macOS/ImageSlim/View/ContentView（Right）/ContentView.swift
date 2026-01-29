//
//  ContentView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appStorage: AppStorage
    var body: some View {
        switch appStorage.selectedView {
        case .compression:
            Workspace(type: .compression)
        case .conversion:
            Workspace(type: .conversion)
        case .settings:
            SettingsView()
        case .statistics:
            Statistics()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStorage.shared)
    // .environment(\.locale, .init(identifier: "ml")) // 设置为马拉雅拉姆语
}
