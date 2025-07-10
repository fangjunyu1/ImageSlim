//
//  SettingsView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//
// 设置视图
// 设置压缩配置等参数

import SwiftUI

struct SettingsView: View {
    @ObservedObject var appStorage = AppStorage.shared
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Application").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "slider.horizontal.2.square")
                            Text("Show icon in menu bar")
                            Spacer()
                            Picker("显示图标", selection: Binding(get: {
                                appStorage.displayMenuBarIcon
                            }, set: { value, _ in
                                appStorage.displayMenuBarIcon = value
                            })) {
                                Text("Always show").tag(true)
                                Text("Off").tag(false)
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(width: 120)
                        }
                    }
                    .padding(8)
                    .background(Color(hex: "EEEEEE"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray.opacity(0.3), lineWidth: 0.5) // 设置边框颜色和宽度
                    )
                }
            }
        }
        .modifier(WindowsModifier())
        .frame(alignment: .leading)
    }
}

#Preview {
    SettingsView()
}
