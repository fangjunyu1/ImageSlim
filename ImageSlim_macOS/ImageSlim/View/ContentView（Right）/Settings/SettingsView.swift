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
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStorage: AppStorage
    @Environment(\.openURL) var openURL
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            // 应用程序
            VStack(alignment: .leading) {
                Section(header:
                            Text("Application")
                    .font(.headline)
                ) {
                    // 应用程序 - 功能模块
                    VStack(alignment: .leading, spacing: 10) {
                        
                        // 在菜单栏中显示图标
                        SettingsItemView(
                            icon:"macwindow",
                            title: "Show in Menu Bar",
                            type: .PickerIcon($appStorage.displayMenuBarIcon))
                        Divider().padding(.leading,25)
                        
                        // 图片压缩率
                        SettingsItemView(
                            icon: "arrow.down.forward.and.arrow.up.backward",
                            title: "Compression Ratio",
                            type: .CompressionSlider($appStorage.imageCompressionRate))
                        Divider().padding(.leading,25)
                        
                        // 图片预览方式
                        SettingsItemView(
                            icon: "plus.magnifyingglass",
                            title: "Preview Mode",
                            type: .PickerPreview($appStorage.imagePreviewMode))
                        
                        Divider().padding(.leading,25)
                        
                        // 图片保存目录
                        SettingsItemView(
                            icon: "square.and.arrow.down",
                            title: "Save Location",
                            type: .SaveLocationButton)
                        
                        Divider().padding(.leading,25)
                        
                        // 启用第三方库压缩
                        SettingsItemView(
                            icon: "square.stack.3d.down.right",
                            title: "Use Third-Party Libraries",
                            type: .ToggleThirdParty(
                                pngquant: $appStorage.enablePngquant,
                                gifsicle: $appStorage.enableGifsicle,
                                cwebp: $appStorage.enableCwebp
                            )
                        )
                        
                        Divider().padding(.leading,25)
                        
                        // 保持原文件名
                        SettingsItemView(
                            icon: "ellipsis.curlybraces",
                            title: "Keep Original Name",
                            type: .Toggle("Keep Original Name",
                                          $appStorage.keepOriginalFileName)
                        )
                        
                        Divider().padding(.leading,25)
                        
                        // 启用图片转换
                        SettingsItemView(
                            icon: "repeat",
                            title: "Enable Image Conversion",
                            type: .Toggle("Enable Image Conversion",$appStorage.EnableImageConversion)
                        )
                        
                        Divider().padding(.leading,25)
                        
                        // 启用统计功能
                        SettingsItemView(
                            icon: "chart.bar",
                            title: "Enable Statistics",
                            type: .Toggle("Enable Statistics",$appStorage.enableStatistics)
                        )
                        
                        Divider().padding(.leading,25)
                        
                        // 临时文件占用
                        SettingsItemView(
                            icon: "tray",
                            title: "Temp Storage Used",
                            type: .TempStorageUsed
                        )
                    }
                    .modifier(SettingsVSModifier())
                }
                
                Spacer().frame(height:20)
                // 关于
                Section(header:
                            Text("About")
                    .font(.headline)
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        // 使用条例
                        SettingsItemView(
                            icon: "text.justify",
                            title: "Terms of use",
                            type: .Link(
                                "Web page (Chinese)",
                                url: "https://fangjunyu.com/2025/07/11/%e8%bd%bb%e5%8e%8b%e5%9b%be%e7%89%87%e4%bd%bf%e7%94%a8%e6%9d%a1%e6%ac%be/"))
                        
                        Divider().padding(.leading,25)
                        
                        // 隐私政策
                        SettingsItemView(
                            icon: "lock",
                            title: "Privacy policy",
                            type: .Link(
                                "Web page (Chinese)",
                                url: "https://fangjunyu.com/2025/07/11/%e8%bd%bb%e5%8e%8b%e5%9b%be%e7%89%87%e9%9a%90%e7%a7%81%e6%94%bf%e7%ad%96/"))
                        
                        Divider().padding(.leading,25)
                        
                        // 问题反馈
                        SettingsItemView(
                            icon: "exclamationmark.bubble",
                            title: "Issue feedback",
                            type: .SendEmail("Email feedback"))
                        
                        Divider().padding(.leading,25)
                        
                        // 开源
                        SettingsItemView(
                            icon: "checkmark.seal",
                            title: "Open source",
                            type: .Link(
                                "GitHub",
                                url: "https://github.com/fangjunyu1/ImageSlim"))
                        
                        Divider().padding(.leading,25)
                        
                        // 鸣谢
                        SettingsItemView(
                            icon: "leaf",
                            title: "Acknowledgements",
                            type: .Thanks(
                                [
                                    ("Pngquant","https://pngquant.org/"),
                                    ("Gifsicle","https://www.lcdf.org/gifsicle/"),
                                    ("Freepik","https://www.freepik.com/"),
                                    ("Zip","https://github.com/marmelroy/Zip"),
                                    ("Cwebp","https://chromium.googlesource.com/webm/libwebp")
                                ])
                        )
                    }
                    .modifier(SettingsVSModifier())
                }
                
                Spacer().frame(height:20)
            }
        }
        .modifier(WindowsModifier())
    }
}

#Preview {
    SettingsView()
        .frame(width: 400)
        .environmentObject(AppStorage.shared)
    // .environment(\.locale, .init(identifier: "ml")) // 设置为马拉雅拉姆语
}
