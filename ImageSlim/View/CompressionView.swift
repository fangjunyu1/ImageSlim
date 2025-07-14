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
    @State private var previewer = ImagePreviewWindow()
    @ObservedObject var appStorage = AppStorage.shared
    @ObservedObject var compressManager = CompressionManager.shared
    @State private var isHovering = false
    @State private var showImporter = false
    
    // 将图片存储到照片并返回URL,将临时文件路径存储到 Temporary 文件夹，并返回 URL
    func getFileSize(fileURL: URL) -> Int {
        let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
        let diskSize = resourceValues?.totalFileAllocatedSize ?? 0
        
        // 获取文件的实际大小
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
        
        // 当macOS上有图像大小，以macOS上图像字节为准。
        // 如果macOS上没有图像大小，以获取的图像字节为准。
        return diskSize > 0 ? diskSize : attributes ?? 0
        
    }
    
    // 将图片存储到照片并返回URL,将临时文件路径存储到 Temporary 文件夹，并返回 URL
    func saveURLToTempFile(fileURL: URL) -> URL? {
        let fileManager = FileManager.default
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileURL.lastPathComponent)
        
        // 如果目标已存在，删除旧的
        try? fileManager.removeItem(at: destinationURL)
        
        do {
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            return destinationURL
        } catch {
            print("复制失败: \(error)")
            return destinationURL
        }
    }
    
    // 根据获取的 URL，存储图像到 CustomImages 数组中
    func savePictures(url tmpURL: [URL]) {
        var compressImages: [CustomImages] = []
        
        for url in tmpURL {
            // 获取 Finder 上的大小
            let fileSize = getFileSize(fileURL: url)
            
            // 根据 URL 获取 NSImage，将图片、名称、类型、大小都保存到 AppStorage的images数组中
            if let nsImage = NSImage(contentsOf: url) {
                let customImage = CustomImages(image: nsImage, name: url.lastPathComponent, type: url.pathExtension.uppercased(), inputSize: fileSize,inputURL: url)
                compressImages.append(customImage)
                DispatchQueue.main.async {
                    appStorage.images.append(customImage)
                }
            }
        }
        
        // 显示全部上传的图片，开始压缩
        compressManager.enqueue(compressImages)    // 立即压缩
    }
    
    var body: some View {
        VStack {
            if !appStorage.images.isEmpty {
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
                        if appStorage.inAppPurchaseMembership {
                            Text("Supports multiple formats such as .png, .jpeg, .gif, .bmp, .tiff, etc.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        } else if !appStorage.images.isEmpty {
                            HStack(spacing: 0) {
                                Text("Number of uploaded pictures")
                                Text(" : \(appStorage.images.count) / \(appStorage.limitImageNum)")
                            }
                            .font(.footnote)
                            .foregroundColor(appStorage.images.count >= appStorage.limitImageNum ? .red : .gray)
                        } else {
                            Text("Select up to 20 pictures, each no larger than 5MB.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                        .frame(width: 30)
                    // 图像
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
                    .onTapGesture {
                        showImporter = true
                    }
                    .onHover(perform: { isHovering in
                        if isHovering {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    })
                    
                    Spacer()
                }
                .frame(height: 140)
                // 图片列表
                ScrollView(showsIndicators:false) {
                    ForEach(Array(appStorage.images.enumerated()),id: \.offset) { index,item in
                        ImageRowView(item: item,index: index,previewer: previewer)
                        .frame(maxWidth: .infinity)
                        .frame(height:42)
                        // 分割线
                        Divider()
                            .padding(.leading,55)
                            .opacity(appStorage.images.count - 1 == index ? 0 : 1)
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
                    
                    if appStorage.inAppPurchaseMembership {
                        Text("Supports multiple formats such as .png, .jpeg, .gif, .bmp, .tiff, etc.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        Text("Select up to 20 pictures, each no larger than 5MB.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    
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
                    .onHover(perform: { isHovering in
                        if isHovering {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    })
                    .onTapGesture {
                        showImporter = true
                    }
                    Spacer().frame(height: 60)
                    
                }
            }
        }
        .modifier(WindowsModifier())
        .onDrop(of: [.image], isTargeted: $isHovering) { providers in
            
            let islimitImagesNum = appStorage.inAppPurchaseMembership ? false : true
            var limitNum = appStorage.limitImageNum - appStorage.images.count
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
                              let imageURL = saveURLToTempFile(fileURL: fileURL) else { return }
                        imageURLs.append(imageURL)
                    }
                }
                limitNum -= 1
            }
            
            group.notify(queue: .main) {
                print("所有图片加载完毕: \(imageURLs.count)")
                savePictures(url: imageURLs)
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
                var limitNum = appStorage.limitImageNum - appStorage.images.count
                var imageURLs: [URL] = []
                
                // 沙盒权限权限请求
                for selectedFile in selectedFiles {
                    // 非内购用户，判断图片是否为最大上传数量
                    if islimitImagesNum && limitNum <= 0 {
                        print("当前已经有 \(appStorage.images.count) 张图片，不再接收新的图片")
                        break
                    }
                    
                    guard selectedFile.startAccessingSecurityScopedResource() else {
                        print("无文件访问权限")
                        return
                    }
                    
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    
                    // 根据 fileURL 保存图像
                    guard let fileURL = saveURLToTempFile(fileURL: selectedFile) else { return }
                    print("插入一张图片")
                    imageURLs.append(fileURL)
                    
                    // 可上传图像数量 - 1
                    limitNum -= 1
                }
                
                savePictures(url: imageURLs)
            } catch {
                print("导入图片失败！")
            }
        }
    }
}

#Preview {
    CompressionView()
}
