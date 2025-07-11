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
    
    var compressionLocalizedKey: LocalizedStringKey  {
        let rate = appStorage.imageCompressionRate
        if rate < 0.3 {
            return "Lowest"
        } else if rate < 0.5 {
            return "Low Quality"
        } else if rate < 0.7 {
            return "Balanced"
        } else if rate < 0.9 {
            return "High Quality"
        } else {
            return "Lossless"
        }
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header:
                    Text("Application")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading) // 强制左对齐
                ) {
                    // 应用程序 - 功能模块
                    VStack(alignment: .leading, spacing: 10) {
                        // 在菜单栏中显示图标
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
                            .fixedSize() // 不随容器拉伸
                        }
                        Divider().padding(.leading,25)
                        
                        // 图片压缩率
                        HStack {
                            Image(systemName: "zipper.page")
                            Text("Image compression rate")
                            Spacer()
                            Text(compressionLocalizedKey)
                            Slider(value: Binding(get: {
                                appStorage.imageCompressionRate
                            }, set: {newValue,_ in
                                appStorage.imageCompressionRate = newValue
                                print("当前newValue:\(newValue)")
                            }),in: 0.2...1,step: 0.2)
                            .frame(width: 100)
                        }
                        Divider().padding(.leading,25)
                        
                        // 图片预览方式
                        HStack {
                            Image(systemName: "plus.magnifyingglass")
                            Text("Show icon in menu bar")
                            Spacer()
                            Picker("显示图标", selection: Binding(get: {
                                appStorage.imagePreviewMode
                            }, set: { value, _ in
                                appStorage.imagePreviewMode = value
                            })) {
                                Text("Window preview").tag(PreviewMode.window)
                                Text("Use Quick Look to preview").tag(PreviewMode.quickLook)
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .fixedSize() // 不随容器拉伸
                        }
                    }
                    .padding(14)
                    .background(Color(hex: "EEEEEE"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray.opacity(0.3), lineWidth: 0.5) // 设置边框颜色和宽度
                    )
                }
            }
            Spacer()
        }
        .modifier(WindowsModifier())
        .frame(alignment: .leading)
    }
}

#Preview {
    SettingsView()
}
