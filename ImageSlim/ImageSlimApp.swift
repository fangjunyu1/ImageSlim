//
//  ImageSlimApp.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/18.
//

import SwiftUI

@main
struct ImageSlimApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 空 Scene，窗口由 AppDelegate 管理
        Settings {
            SettingsView()
        }  // 占位，不弹出任何窗口

    }
}
