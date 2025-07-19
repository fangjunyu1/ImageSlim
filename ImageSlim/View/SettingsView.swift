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
    @ObservedObject var appStorage = AppStorage.shared
    @Environment(\.openURL) var openURL
    
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
    
    func sendEmail() {
        let email = "fangjunyu.com@gmail.com"
        let subject = "ImageSlim"
        let body = "Hi fangjunyu,\n\n"
        
        // URL 编码参数
        let urlString = "mailto:\(email)?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if let url = URL(string: urlString ?? "") {
            NSWorkspace.shared.open(url)
        }
    }
    
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
                            Image(systemName: "numbers.rectangle")
                            Text("Image compression rate")
                            Spacer()
                            Text(compressionLocalizedKey)
                            Slider(value: Binding(get: {
                                appStorage.imageCompressionRate
                            }, set: {newValue,_ in
                                // 处理 Slider 浮点数精度误差，如0.600000000001
                                let rounded = round(newValue * 10) / 10
                                appStorage.imageCompressionRate = rounded
                                print("当前rounded:\(rounded)")
                            }),in: 0...1,step: 0.25)
                            .frame(width: 100)
                        }
                        
                        Divider().padding(.leading,25)
                        
                        // 图片预览方式
                        HStack {
                            Image(systemName: "plus.magnifyingglass")
                            Text("Show icon in menu bar")
                            Spacer()
                            Picker("预览方式", selection: Binding(get: {
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
                        
                        Divider().padding(.leading,25)
                        
                        // 图片保存目录
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Image save directory")
                            Spacer()
                            Picker("选择目录", selection: Binding(get: {
                                appStorage.imageSaveDirectory
                            }, set: { value, _ in
                                appStorage.imageSaveDirectory = value
                            })) {
                                Text("Download directory").tag(SaveDirectory.downloadsDirectory)
//                                Text("Image directory").tag(SaveDirectory.picturesDirectory)
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .fixedSize() // 不随容器拉伸
                        }
                        
                        Divider().padding(.leading,25)
                        
                        // 启用第三方库压缩
                        HStack {
                            Image(systemName: "zipper.page")
                            Text("Enable third-party library compression")
                            Spacer()
                            if appStorage.enableThirdPartyLibraries {
                                Text("pngquant")
                                    .foregroundColor(.gray)
                            }
                            Toggle("启用第三方库压缩",isOn: Binding(get: {
                                appStorage.enableThirdPartyLibraries
                            }, set: { newValue in
                                appStorage.enableThirdPartyLibraries = newValue
                            }))
                            .labelsHidden()
                        }
                    }
                    .padding(14)
                    .background(colorScheme == .light ? Color(hex: "EEEEEE") : .clear)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray.opacity(0.3), lineWidth: 0.5) // 设置边框颜色和宽度
                    )
                }
                
                Spacer().frame(height:20)
                
                // 关于
                Section(header:
                            Text("About")
                    .font(.headline)
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        // 使用条例
                        HStack {
                            Image(systemName: "chart.bar.horizontal.page")
                            Text("Terms of use")
                            Spacer()
                            Text("Web page (Chinese)")
                                .foregroundColor(.gray)
                        }
                        .onTapGesture {
                            if let url = URL(string: "https://fangjunyu.com/2025/07/11/%e8%bd%bb%e5%8e%8b%e5%9b%be%e7%89%87%e4%bd%bf%e7%94%a8%e6%9d%a1%e6%ac%be/") {
                                openURL(url)
                            }
                        }
                        .onHover { isHovering in
                            isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                        }
                        
                        Divider().padding(.leading,25)
                        
                        // 隐私政策
                        HStack {
                            Image(systemName: "lock.document")
                            Text("Privacy policy")
                            Spacer()
                            Text("Web page (Chinese)")
                                .foregroundColor(.gray)
                        }
                        .onTapGesture {
                            if let url = URL(string: "https://fangjunyu.com/2025/07/11/%e8%bd%bb%e5%8e%8b%e5%9b%be%e7%89%87%e9%9a%90%e7%a7%81%e6%94%bf%e7%ad%96/") {
                                openURL(url)
                            }
                        }
                        .onHover { isHovering in
                            isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                        }
                        
                        Divider().padding(.leading,25)
                        
                        // 问题反馈
                        HStack {
                            Image(systemName: "exclamationmark.bubble")
                            Text("Issue feedback")
                            Spacer()
                            Text("Email feedback")
                                .foregroundColor(.gray)
                        }
                        .onTapGesture {
                            sendEmail()
                        }
                        .onHover { isHovering in
                            isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                        }
                        
                        Divider().padding(.leading,25)
                        
                        // 开源
                        HStack {
                            Image(systemName: "checkmark.seal")
                            Text("Open source")
                            Spacer()
                            Text("GitHub")
                                .foregroundColor(.gray)
                        }
                        .onTapGesture {
                            if let url = URL(string: "https://github.com/fangjunyu1/ImageSlim") {
                                openURL(url)
                            }
                        }
                        .onHover { isHovering in
                            isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                        }
                        
                        Divider().padding(.leading,25)
                        
                        // 鸣谢
                        HStack {
                            Image(systemName: "leaf")
                            Text("Acknowledgements")
                            Spacer()
                            HStack(spacing:0) {
                                Text("pngquant")
                                    .onTapGesture {
                                        if let url = URL(string: "https://pngquant.org/") {
                                            openURL(url)
                                        }
                                    }
                                    .onHover { isHovering in
                                        isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                                    }
                                Text("、")
                                Text("Freepik")
                                    .onTapGesture {
                                        if let url = URL(string: "https://www.freepik.com/") {
                                            openURL(url)
                                        }
                                    }
                                    .onHover { isHovering in
                                        isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                                    }
                                Text("、")
                                Text("Zip")
                                    .onTapGesture {
                                        if let url = URL(string: "https://github.com/marmelroy/Zip") {
                                            openURL(url)
                                        }
                                    }
                                    .onHover { isHovering in
                                        isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                                    }
                                Text("、")
                                Text("ChatGPT")
                                    .onTapGesture {
                                        if let url = URL(string: "https://chatgpt.com/") {
                                            openURL(url)
                                        }
                                    }
                                    .onHover { isHovering in
                                        isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                                    }
                            }
                            .foregroundColor(.gray)
                        }
                    }
                    .padding(14)
                    .background(colorScheme == .light ? Color(hex: "EEEEEE") : .clear)
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
    }
}

#Preview {
    SettingsView()
        .frame(width: 400)
        .environment(\.locale, .init(identifier: "ml")) // 设置为马拉雅拉姆语
}
