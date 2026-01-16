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
                            icon:"slider.horizontal.2.square",
                            title: "Show icon in menu bar",
                            type: .PickerIcon($appStorage.displayMenuBarIcon))
                        Divider().padding(.leading,25)
                        
                        // 图片压缩率
                        SettingsItemView(
                            icon: "numbers.rectangle",
                            title: "Image compression rate",
                            type: .CompressionSlider($appStorage.imageCompressionRate))
                        Divider().padding(.leading,25)
                        
                        // 图片预览方式
                        SettingsItemView(
                            icon: "plus.magnifyingglass",
                            title: "Image preview method",
                            type: .PickerPreview($appStorage.imagePreviewMode))
                        
                        Divider().padding(.leading,25)
                        
                        // 图片保存目录
                        SettingsItemView(
                            icon: "square.and.arrow.down",
                            title: "Save location",
                            type: .SaveLocationButton)
                        
                        Divider().padding(.leading,25)
                        
                        // 启用第三方库压缩
                        SettingsItemView(
                            icon: "zipper.page",
                            title: "Enable third-party library compression",
                            type: .ToggleThirdParty(
                                pngquant: $appStorage.enablePngquant,
                                gifsicle: $appStorage.enableGifsicle
                            )
                        )
                        
                        Divider().padding(.leading,25)
                        
                        // 保持原文件名
                        SettingsItemView(
                            icon: "ellipsis.curlybraces",
                            title: "Keep the original file name",
                            type: .Toggle("Keep the original file name",
                                          $appStorage.keepOriginalFileName)
                        )
                        
                        Divider().padding(.leading,25)
                        
                        // 启用图片转换
                        SettingsItemView(
                            icon: "arrow.down.left.arrow.up.right",
                            title: "EnableImageConversion",
                            type: .Toggle("EnableImageConversion",$appStorage.EnableImageConversion)
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
                            icon: "chart.bar.horizontal.page",
                            title: "Terms of use",
                            type: .Link(
                                "Web page (Chinese)",
                                url: "https://fangjunyu.com/2025/07/11/%e8%bd%bb%e5%8e%8b%e5%9b%be%e7%89%87%e4%bd%bf%e7%94%a8%e6%9d%a1%e6%ac%be/"))
                        
                        Divider().padding(.leading,25)
                        
                        // 隐私政策
                        SettingsItemView(
                            icon: "lock.document",
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
                                    ("Zip","https://github.com/marmelroy/Zip")
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
