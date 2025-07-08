//
//  CompressionView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//
// 压缩视图
// 显示压缩图片的界面，上传/下载压缩图片
//

import SwiftUI
import UniformTypeIdentifiers

struct CompressionView: View {
    @ObservedObject var data = TemporaryData.shared
    @State private var isHovering = false
    @State private var images:[CustomImages] = []
    
    var body: some View {
        VStack {
            if data.displayImageQueue {
                HStack {
                    Spacer()
                    VStack {
                        if isHovering {
                            Text("Release the file and add compression")
                                .font(.title)
                        } else {
                            Text("Upload pictures and compress them instantly")
                                .font(.title)
                        }
                        Spacer().frame(height:20)
                        Text("Select up to 20 pictures, each no larger than 5MB.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                        .frame(width: 30)
                    ZStack {
                        Rectangle()
                            .frame(width: 150,height: 100)
                            .foregroundColor(isHovering ? Color(hex: "BEE2FF") : Color(hex:"E6E6E6"))
                            .shadow(color: .gray.opacity(0.6), radius: 2, x: 0, y: 4)
                        Image("upload")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100)
                    }
                    Spacer()
                }
            } else {
                VStack {
                    if isHovering {
                        Text("Release the file and add compression")
                            .font(.title)
                    } else {
                        Text("Upload pictures and compress them instantly")
                            .font(.title)
                    }
                    
                    Spacer().frame(height:14)
                    
                    Text("Select up to 20 pictures, each no larger than 5MB.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Spacer().frame(height:20)
                    
                    ZStack {
                        Rectangle()
                            .frame(width: 240,height: 160)
                            .foregroundColor(isHovering ? Color(hex: "BEE2FF") : Color(hex:"E6E6E6"))
                            .shadow(color: .gray.opacity(0.6), radius: 2, x: 0, y: 4)
                        Image("upload")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150)
                    }
                    Spacer().frame(height: 60)
                }
            }
        }
        .modifier(WindowsModifier())
        .onDrop(of: [.image], isTargeted: $isHovering) { providers in
            for provider in providers {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) {data,error in
                    if let data = data {
                        if let nsImage = NSImage(data: data) {
                            let image = Image(nsImage: nsImage)
                            let customImage = CustomImages(id: UUID(), image: image, name: "测试", type: "png", inputSize: 3000)
                            images.append(customImage)
                        } else {
                            print("从 NSImage 获取的图片转换 Image 类型失败")
                        }
                        // 使用 image
                    } else {
                        print("加载失败: \(error?.localizedDescription ?? "未知错误")")
                    }
                }
            }
            // 处理 NSItemProvider 列表
            return true // 返回是否接受了拖入内容
        }
    }
}

#Preview {
    CompressionView()
}
