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
import AppKit
import UniformTypeIdentifiers

struct CompressionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStorage: AppStorage
    @StateObject var compressManager = CompressionManager.shared
    @State private var previewer = ImagePreviewWindow()
    @State private var isHovering = false   // 图片悬浮时
    @State private var showImporter = false
    
    var body: some View {
        VStack {
            AdaptiveContentView(isEmpty: appStorage.compressedImages.isEmpty, title: {
                if isHovering {
                    // 释放文件，添加压缩
                    Text("Release the file and add compression")
                        .font(.title)
                } else {
                    // 上传图片，即刻压缩
                    Text("Upload pictures and compress them instantly")
                        .font(.title)
                }
            }, tips: {
                if appStorage.inAppPurchaseMembership {
                    // 支持 .png, .jpeg, .bmp, .tiff 等各种格式。
                    Text("Supports multiple formats including .png, .jpeg, .bmp, .tiff, etc.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                } else {
                    // 最多选择 20 张图片，每张大小不超过 5MB。
                    Text("Select up to 20 pictures, each no larger than 5MB.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }, zstack: {
                // 显示的图片区域
                ZStack {
                    Rectangle()
                        .frame(width: 240,height: 160)
                        .foregroundColor(
                            isHovering ? colorScheme == .light ? Color(hex: "BEE2FF") : Color(hex: "3d3d3d") :
                                colorScheme == .light ?  Color(hex:"E6E6E6") : Color(hex: "2f2f2f")
                        )
                        .cornerRadius(5)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 4)
                    Image("upload")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                }
                .modifier(HoverModifier())
                .onTapGesture {
                    showImporter = true
                }
            }, list: {
                // 图片列表
                ScrollView(showsIndicators:false) {
                    ForEach(Array(appStorage.compressedImages.enumerated()),id: \.offset) { index,item in
                        ImageRowView(item: item,index: index,previewer: previewer,imageType: .compression)
                            .frame(maxWidth: .infinity)
                            .frame(height:42)
                        // 分割线
                        Divider()
                            .padding(.leading,55)
                            .opacity(appStorage.compressedImages.count - 1 == index ? 0 : 1)
                    }
                }
                .frame(maxWidth: .infinity,maxHeight: .infinity)
                .padding(.vertical,20)
                .padding(.horizontal,30)
                .background(colorScheme == .light ? .white : Color(hex: "222222"))
                .cornerRadius(10)
            })
        }
        .environmentObject(compressManager)
        .modifier(WindowsModifier())
        .onDrop(of: [.image], isTargeted: $isHovering) { providers in
            
            let islimitImagesNum = appStorage.inAppPurchaseMembership ? false : true
            var limitNum = appStorage.limitImageNum - appStorage.compressedImages.count
            var imageURLs: [URL] = []
            let group = DispatchGroup()
            
            for provider in providers {
                
                // 非内购用户，判断图片是否为最大上传数量
                if islimitImagesNum && limitNum <= 0 {
                    break
                }
                
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                        defer { group.leave() }
                        guard let fileURL = url,
                              let imageURL = FileUtils.saveURLToTempFile(fileURL: fileURL) else { return }
                        imageURLs.append(imageURL)
                    }
                }
                limitNum -= 1
            }
            
            group.notify(queue: .main) {
                print("所有图片加载完毕: \(imageURLs.count)")
                compressManager.savePictures(url: imageURLs)
            }
            
            // 处理 NSItemProvider 列表
            return true // 返回是否接受了拖入内容
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            print("开始导入图片")
            // 处理选择结果
            do {
                let selectedFiles: [URL] = try result.get()
                
                let islimitImagesNum = appStorage.inAppPurchaseMembership ? false : true
                var limitNum = appStorage.limitImageNum - appStorage.compressedImages.count
                var imageURLs: [URL] = []
                
                // 沙盒权限权限请求
                for selectedFile in selectedFiles {
                    // 非内购用户，判断图片是否为最大上传数量
                    if islimitImagesNum && limitNum <= 0 {
                        print("当前已经有 \(appStorage.compressedImages.count) 张图片，不再接收新的图片")
                        break
                    }
                    
                    guard selectedFile.startAccessingSecurityScopedResource() else {
                        print("无文件访问权限")
                        return
                    }
                    
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    
                    // 根据 fileURL 保存图像
                    guard let fileURL = FileUtils.saveURLToTempFile(fileURL: selectedFile) else { return }
                    print("插入一张图片")
                    imageURLs.append(fileURL)
                    
                    // 可上传图像数量 - 1
                    limitNum -= 1
                }
                
                compressManager.savePictures(url: imageURLs)
            } catch {
                print("导入图片失败！")
            }
        }
        .onReceive(KeyboardMonitor.shared.pastePublisher) { _ in
            print("支持的格式有：\(NSPasteboard.general.types ?? [])")
            let pb = NSPasteboard.general
            var compressImages: [CustomImages] = []
            
            if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
                print("粘贴的是URL数组")
                // 读取urls文件
                for url in urls {
                    // 获取 Finder 上的大小
                    let fileSize = FileUtils.getFileSize(fileURL: url)
                    
                    // 加载图片对象
                    guard let nsImage = NSImage(contentsOf: url) else {
                        print("无法加载粘贴的图片")
                        continue
                    }
                    
                    let imageName = url.lastPathComponent
                    let imageType = url.pathExtension.uppercased()
                    
                    var compressionState: CompressionState = .pending

                    if !appStorage.inAppPurchaseMembership && fileSize > appStorage.limitImageSize {
                        print("文件过大跳过:\(imageName),文件大小为:\(fileSize)")
                        compressionState = .failed
                    }
                    print("当前内购状态:\(appStorage.inAppPurchaseMembership),fileSize:\(fileSize)")
                    // 内购用户 or 文件大小合规
                    let customImage = CustomImages(
                        image: nsImage,
                        name: imageName,
                        type: imageType,
                        inputSize: fileSize,
                        inputURL: url,
                        compressionState: compressionState
                    )
                    
                    DispatchQueue.main.async {
                        appStorage.compressedImages.append(customImage)
                    }

                    if compressionState == .pending {
                        compressImages.append(customImage)
                    }
                }
            } else if let imageData = pb.data(forType: .tiff) {
                print("粘贴的是图片")
                //pastedImage = image
                // 将粘贴的图片转换成png格式
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
                
                do {
                    try imageData.write(to: url)
                    
                    // 获取 Finder 上的大小
                    let fileSize = FileUtils.getFileSize(fileURL: url)
                    
                    // 加载图片对象
                    guard let nsImage = NSImage(contentsOf: url) else {
                        print("无法加载粘贴的图片")
                        return
                    }
                    
                    let imageName = url.lastPathComponent
                    let imageType = url.pathExtension.uppercased()
                    
                    var compressionState: CompressionState = .pending

                    if !appStorage.inAppPurchaseMembership && fileSize > appStorage.limitImageSize {
                        print("文件过大跳过:\(imageName),文件大小为:\(fileSize)")
                        compressionState = .failed
                    }
                    print("当前内购状态:\(appStorage.inAppPurchaseMembership),fileSize:\(fileSize)")
                    // 内购用户 or 文件大小合规
                    let customImage = CustomImages(
                        image: nsImage,
                        name: imageName,
                        type: imageType,
                        inputSize: fileSize,
                        inputURL: url,
                        compressionState: compressionState
                    )
                    
                    DispatchQueue.main.async {
                        appStorage.compressedImages.append(customImage)
                    }

                    if compressionState == .pending {
                        compressImages.append(customImage)
                    }
                } catch {
                    print("粘贴板写入过程发生报错")
                }
            } else if let str = pb.string(forType: .string) {
                print("粘贴的字符串为：\(str)")
                // pastedText = str
            } else {
                print("剪贴板中无可识别内容")
                // pastedImage = nil
            }
            // for-in循环结束，开始调用压缩图片
            compressManager.enqueue(compressImages)
        }
        
    }
}

#Preview {
    CompressionView()
        .environmentObject(AppStorage.shared)
        // .environment(\.locale, .init(identifier: "ml")) // 设置为马拉雅拉姆语
}
