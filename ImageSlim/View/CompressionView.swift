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
    @ObservedObject var tmpData = TemporaryData.shared
    @State private var isHovering = false
    
    var body: some View {
        VStack {
            if !tmpData.images.isEmpty {
                // 上传图片提示语
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
                .frame(height: 140)
                // 图片列表
                ScrollView(showsIndicators:false) {
                    ForEach(Array(tmpData.images.enumerated()),id: \.offset) { index,item in
                        HStack {
                            item.image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .cornerRadius(5)
                            Spacer().frame(width:20)
                            // 单个图片
                            VStack(alignment: .leading) {
                                // 图片名称
                                    Text("\(item.name)")
                                        .frame(width: 150, alignment: .leading)
                                        .lineLimit(1)
                                Spacer().frame(height:3)
                                // 图片信息
                                HStack {
                                    ZStack {
                                        Rectangle()
                                            .foregroundColor(Color(hex: "91C9FF"))
                                            .frame(width:50,height:16)
                                            .cornerRadius(3)
                                        Text("\(item.type)")
                                            .font(.footnote)
                                            .foregroundColor(.white)
                                            .cornerRadius(5)
                                    }
                                    Text("\(item.inputSize)")
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(minWidth:40)
                            Spacer()
                            
                            // 输出参数
                            VStack(alignment: .trailing) {
                                // 压缩占比
                                Text("-\(Int((item.compressionRatio ?? 0) * 100))%")
                                Spacer().frame(height:3)
                                // 输出图片大小
                                 Text("\(item.outputSize ?? 0)")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer().frame(width:10)
                            
                            // 下载按钮
                            Button(action: {
                                
                            }, label: {
                                Text("Download")
                                    .foregroundColor(Color(hex: "3679F6"))
                                    .padding(.vertical,5)
                                    .padding(.horizontal,20)
                                    .background(Color(hex: "EEEEEE"))
                                    .cornerRadius(20)
                            })
                            .frame(width: 70)
                            .buttonStyle(.plain)
                            
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height:42)
                        // 分割线
                        Divider()
                            .padding(.leading,55)
                            .opacity(tmpData.images.count - 1 == index ? 0 : 1)
                    }
                }
                .frame(maxWidth: .infinity,maxHeight: .infinity)
                .padding(.vertical,20)
                .padding(.horizontal,30)
                .background(.white)
                .cornerRadius(10)
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
                            DispatchQueue.main.async {
                                let customImage = CustomImages(id: UUID(), image: image, name: "测试", type: "png", inputSize: 3000)
                                tmpData.images.append(customImage)
                            }
                        } else {
                            DispatchQueue.main.async {
                                print("从 NSImage 获取的图片转换 Image 类型失败")
                            }
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
        // 测试图片
//        .onAppear {
//            for i in 0...2 {
//                let customImage = CustomImages(id: UUID(), image: Image("upload"), name: "测试", type: "png", inputSize: 3000)
//                images.append(customImage)
//            }
//        }
    }
}

#Preview {
    CompressionView()
}
