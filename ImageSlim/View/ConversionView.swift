//
//  ConversionView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/8/25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ConversionView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var previewer = ImagePreviewWindow()
    @ObservedObject var appStorage = AppStorage.shared
    @ObservedObject var conversionManager = ConversionManager.shared
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
        print("进入 savePictures 方法")
        var compressImages: [CustomImages] = []
        for url in tmpURL {
            
            // 获取 Finder 上的大小
            let fileSize = getFileSize(fileURL: url)
            
            // 加载图片对象
            guard let nsImage = NSImage(contentsOf: url) else {
                print("无法加载粘贴的图片")
                continue
            }
            
            let imageName = url.lastPathComponent
            let imageType = url.pathExtension.uppercased()
            
            let compressionState: CompressionState = .pending
            
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
                appStorage.conversionImages.append(customImage)
            }
            
            if compressionState == .pending {
                compressImages.append(customImage)
            }
        }
        
        // 显示全部上传的图片，开始压缩
        conversionManager.enqueue(compressImages)    // 立即压缩
    }
    
    var body: some View {
        VStack {
            AdaptiveContentView(isEmpty: appStorage.conversionImages.isEmpty, title: {
                Group {
                    if isHovering {
                        Text("Free files and convert them immediately")
                            .font(.title)
                    } else {
                        HStack {
                            Text("Converting images")
                                .font(.title)
                            Menu {
                                ForEach(ConversionTypeState.allCases) { option in
                                    Button(option.rawValue) {
                                        appStorage.convertTypeState = option
                                    }
                                }
                            } label: {
                                Text(appStorage.convertTypeState.rawValue.uppercased())
                                    .frame(width: 60, height: 30)
                                    .foregroundColor(.white)
                                    .background(Color(hex: "082A7C"))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .onHover(perform: { isHovering in
                                if isHovering {
                                    NSCursor.pointingHand.set()
                                } else {
                                    NSCursor.arrow.set()
                                }
                            })
                        }
                    }
                }
            }, tips: {
                if appStorage.inAppPurchaseMembership {
                    Text("Supports multiple formats including .png, .jpeg, .bmp, .tiff, etc.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                } else {
                    Text("Select up to 20 pictures, each no larger than 5MB.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }, zstack:  {
                ZStack {
                    Rectangle()
                        .frame(width: 240,height: 160)
                        .foregroundColor(
                            isHovering ? colorScheme == .light ? Color(hex: "BEE2FF") : Color(hex: "3d3d3d"):
                                colorScheme == .light ?  Color(hex:"E6E6E6") : Color(hex: "2f2f2f")
                        )
                        .cornerRadius(5)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 4)
                    Image("conversion")
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
            }, list: {
                ScrollView(showsIndicators:false) {
                    ForEach(Array(appStorage.conversionImages.enumerated()),id: \.offset) { index,item in
                        ImageRowConversionView(item: item,index: index,previewer: previewer)
                            .frame(maxWidth: .infinity)
                            .frame(height:42)
                        // 分割线
                        Divider()
                            .padding(.leading,55)
                            .opacity(appStorage.conversionImages.count - 1 == index ? 0 : 1)
                    }
                }
                .frame(maxWidth: .infinity,maxHeight: .infinity)
                .padding(.vertical,20)
                .padding(.horizontal,30)
                .background(colorScheme == .light ? .white : Color(hex: "222222"))
                .cornerRadius(10)
            })
        }
        .modifier(WindowsModifier())
        .onDrop(of: [.image], isTargeted: $isHovering) { providers in
            
            let islimitImagesNum = appStorage.inAppPurchaseMembership ? false : true
            var limitNum = appStorage.limitImageNum - appStorage.conversionImages.count
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
                
                // 如果未赞助，限制导入图片的数量
                let islimitImagesNum = appStorage.inAppPurchaseMembership ? false : true
                var limitNum = appStorage.limitImageNum - appStorage.conversionImages.count
                var imageURLs: [URL] = []
                
                // 沙盒权限权限请求
                for selectedFile in selectedFiles {
                    // 非内购用户，判断图片是否为最大上传数量
                    if islimitImagesNum && limitNum <= 0 {
                        print("当前已经有 \(appStorage.conversionImages.count) 张图片，不再接收新的图片")
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
        .onReceive(KeyboardMonitor.shared.pastePublisher) { _ in
            print("支持的格式有：\(NSPasteboard.general.types ?? [])")
            let pb = NSPasteboard.general
            var compressImages: [CustomImages] = []
            
            if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
                print("粘贴的是URL数组")
                // 读取urls文件
                for url in urls {
                    // 获取 Finder 上的大小
                    let fileSize = getFileSize(fileURL: url)
                    
                    // 加载图片对象
                    guard let nsImage = NSImage(contentsOf: url) else {
                        print("无法加载粘贴的图片")
                        continue
                    }
                    
                    let imageName = url.lastPathComponent
                    let imageType = url.pathExtension.uppercased()
                    
                    var compressionState: CompressionState = .pending
                    
                    if !appStorage.inAppPurchaseMembership && fileSize > 5_000_000 {
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
                        appStorage.conversionImages.append(customImage)
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
                    let fileSize = getFileSize(fileURL: url)
                    
                    // 加载图片对象
                    guard let nsImage = NSImage(contentsOf: url) else {
                        print("无法加载粘贴的图片")
                        return
                    }
                    
                    let imageName = url.lastPathComponent
                    let imageType = url.pathExtension.uppercased()
                    
                    var compressionState: CompressionState = .pending
                    
                    if !appStorage.inAppPurchaseMembership && fileSize > 5_000_000 {
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
                        appStorage.conversionImages.append(customImage)
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
            conversionManager.enqueue(compressImages)
        }
        
    }
}

#Preview {
    ConversionView()
    // .environment(\.locale, .init(identifier: "ml")) // 设置为马拉雅拉姆语
}
