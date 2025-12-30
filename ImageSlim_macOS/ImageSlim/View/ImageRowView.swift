//
//  ImageRowView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/12.
//

import SwiftUI
import QuickLookUI

struct ImageRowView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hoveringIndex: Int? = nil
    @ObservedObject var appStorage = AppStorage.shared
    @ObservedObject var compressManager = CompressionManager.shared
    @ObservedObject var item: CustomImages
    @State private var shakeOffset: CGFloat = 0
    var index: Int
    var previewer: ImagePreviewWindow
    // var completion: () -> Void
    
    // 抖动效果
    private func triggerShake() {
        withAnimation(Animation.linear(duration: 0.1)) {
            shakeOffset = -3
        }
        withAnimation(Animation.linear(duration: 0.1).repeatCount(5, autoreverses: true)) {
            shakeOffset = 6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shakeOffset = 0
        }
    }
    
    // 将图片存储到照片并返回URL
    func saveImageToTempFile(image: NSImage) -> URL? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        try? pngData.write(to: tempURL)
        return tempURL
    }
    
    // 调用 Quick Look 预览图片
    func previewImage(at url: URL) {
        guard let panel = QLPreviewPanel.shared() else { return }
        let dataSource = PreviewDataSource(urls: [url])
        panel.dataSource = dataSource
        panel.makeKeyAndOrderFront(nil)
    }
    
    private func saveImg(file:CustomImages,url:URL) {
        // 获取文件名称，并拆分为 文件名+后缀名
        let nsName = file.name as NSString
        let fileName = nsName.deletingPathExtension    // 获取文件名称， test.zip 获取 test 等。
        let fileExt = nsName.pathExtension    // 获取文件扩展名， test.zip 获取 zip 等。
        // 设置最终名称，如果不保持原文件名称，则拼接_compress，保持原文件名称则显示正常的原文件名称
        let finalName: String
        if !appStorage.keepOriginalFileName {
            print("当前设置为不保持原文件名，因此添加_compress后缀")
            finalName = "\(fileName)_compress.\(fileExt)"
        } else {
            finalName = file.name
        }
        
        // 拼接 目录路径 + 文件名称
        let destinationURL = url.appendingPathComponent(finalName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: file.outputURL!, to: destinationURL)
        } catch {
            print("保存失败：\(error)")
        }
    }
    
    // 下载图片到文件夹
    func saveToDownloads(file: CustomImages) {
        
        // 获取目录路径
        // 如果有安全书签，保存到安全书签的URL
        if let bookmark = UserDefaults.standard.data(forKey: "SaveLocation") {
            var isStale = false
                do {
                    let url = try URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)

                    if url.startAccessingSecurityScopedResource() {
                        saveImg(file: file,url: url)
                        url.stopAccessingSecurityScopedResource()
                    } else {
                        print("无法访问资源")
                    }
                } catch {
                    print("解析书签失败: \(error)")
                }
        } else {
            // 如果没有保存过目录，让用户选择
            askUserForSaveLocation(file: file)
        }
    }
    
    /// 弹出 NSSavePanel 或 NSOpenPanel 让用户选择目录，并保存书签
    func askUserForSaveLocation(file: CustomImages) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        let saveDir = NSLocalizedString("Save location", comment: "选择保存文件夹")
        panel.prompt = saveDir

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let bookmark = try url.bookmarkData(options: [.withSecurityScope],includingResourceValuesForKeys: nil,
                                                    relativeTo: nil)
                UserDefaults.standard.set(bookmark, forKey: "SaveLocation")
                print("书签保存成功")

                if url.startAccessingSecurityScopedResource() {
                    saveImg(file: file, url: url)
                    url.stopAccessingSecurityScopedResource()
                }
            } catch {
                print("书签创建失败: \(error)")
            }
        }
    }
    // 根据图片的字节大小显示适配的存储大小。
    func TranslateSize(fileSize: Int) -> String {
        let num = 1000.0
        let size = Double(fileSize)
        
        func format(_ value: Double) -> String {
            let roundedValue = (value * 10).rounded() / 10
            // 判断是否为整数
            print("1、roundedValue:\(roundedValue)")
            if roundedValue.truncatingRemainder(dividingBy: 1) == 0 {
                print("2、roundedValue:\(roundedValue)")
                return String(format: "%.0f", roundedValue) // 无小数
            } else {
                print("2、roundedValue:\(roundedValue)")
                return String(format: "%.1f", roundedValue) // 一位小数
            }
        }
        
        if size < num {
            return "\(size) B"
        } else if size < pow(num,2.0) {
            let sizeNum = size / pow(num,1)
            return "\(ceil(sizeNum)) KB"
        } else if size < pow(num,3.0) {
            let sizeNum = size / pow(num,2)
            return "\(format(sizeNum)) MB"
        } else if size < pow(num,4.0) {
            let sizeNum = size / pow(num,3)
            return "\(format(sizeNum)) GB"
        } else if size < pow(num,5.0) {
            let sizeNum = size / pow(num,4)
            return "\(format(sizeNum)) TB"
        } else {
            let sizeNum = size / pow(num,5)
            return "\(format(sizeNum)) TB"
        }
    }
    
    var body: some View {
        HStack {
            ZStack {
                Image(nsImage: item.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 35, height: 35)
                Group {
                    Color.gray.opacity(0.3)
                    Image(systemName:"plus.magnifyingglass")
                        .foregroundColor(.white)
                        .allowsHitTesting(false)
                }
                .frame(width: 35, height: 35)
                .zIndex(hoveringIndex == index ? 1 : -1)
            }
            //                            // 悬停显示放大按钮
            .onTapGesture {
                // 根据 AppStorage 选项，选择图片打开方式：
                if appStorage.imagePreviewMode == .quickLook {
                    // 使用 Quick Look 预览图片
                    if let url = saveImageToTempFile(image: item.image) {
                        previewImage(at: url)
                    }
                } else if appStorage.imagePreviewMode == .window {
                    // 使用新窗口预览图片
                    previewer.show(image: Image(nsImage:appStorage.images[index].image))
                }
            }
            .onHover { isHovering in
                // 当鼠标进入视图区域时 isHovering = true
                // 当鼠标离开视图区域时 isHovering = false
                if isHovering {
                    hoveringIndex = index
                } else {
                    hoveringIndex = nil
                }
            }
            .onHover { isHovering in
                isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
            }
            .cornerRadius(4)
            
            Spacer().frame(width:20)
                .background(.green)
            // 图片信息
            VStack(alignment: .leading) {
                // 图片名称
                Text("\(item.name)")
                    .frame(maxWidth: 150, alignment: .leading)
                    .lineLimit(1)
                Spacer().frame(height:3)
                // 图片信息
                HStack {
                    ZStack {
                        Rectangle()
                            .foregroundColor(colorScheme == .light ? Color(hex: "91C9FF") : Color(hex: "6c6c6c"))
                            .frame(width:50,height:16)
                            .cornerRadius(3)
                        Text("\(item.type)")
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    if !appStorage.inAppPurchaseMembership && item.inputSize > appStorage.limitImageSize {
                        Text(TranslateSize(fileSize:item.inputSize))
                            .foregroundColor(.red)
                    } else {
                        Text(TranslateSize(fileSize:item.inputSize))
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            
            // 如果图片完成压缩，显示压缩图片的输出参数和下载按钮
            if item.compressionState == .completed {
                // 输出参数
                VStack(alignment: .trailing) {
                    // 压缩占比
                    Text("-\(Int((item.compressionRatio ?? 0) * 100))%")
                    Spacer().frame(height:3)
                    // 输出图片大小
                    Text(TranslateSize(fileSize:item.outputSize ?? 0))
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                Spacer().frame(width:10)
                
                // 赞助应用，显示下载按钮，未赞助应用，超过5MB的图片显示 锁图标
                if !appStorage.inAppPurchaseMembership && item.inputSize > appStorage.limitImageSize {
                    VStack {
                        Image(systemName:"lock.fill")
                            .foregroundColor(colorScheme == .light ? Color(hex: "3679F6") : .white)
                            .padding(.vertical,5)
                            .padding(.horizontal,20)
                            .offset(x: shakeOffset)
                    }
                    .background(colorScheme == .light ? Color(hex: "EEEEEE") : Color(hex: "555555"))
                    .cornerRadius(20)
                    .onTapGesture {
                        print("抖动锁图标")
                        triggerShake()
                    }
                    .onHover { isHovering in
                        isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                    }
                } else {
                    // 下载按钮
                    Button(action: {
                        saveToDownloads(file: item)
                        print("isDownloaded状态改为true")
                        item.isDownloaded = true
                        // 延时 2 秒后恢复
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            print("isDownloaded状态改为false")
                            item.isDownloaded = false
                        }
                    }) {
                        
                        if item.isDownloaded {
                            Image(systemName:"checkmark")
                                .foregroundColor(colorScheme == .light ? Color(hex: "3679F6") : .white)
                                .padding(.vertical,5)
                                .padding(.horizontal,20)
                                .background(colorScheme == .light ? Color(hex: "EEEEEE") : Color(hex: "555555"))
                                .cornerRadius(20)
                        } else {
                            Text("Download")
                                .foregroundColor(colorScheme == .light ? Color(hex: "3679F6") : .white)
                                .padding(.vertical,5)
                                .padding(.horizontal,20)
                                .background(colorScheme == .light ? Color(hex: "EEEEEE") : Color(hex: "555555"))
                                .cornerRadius(20)
                        }
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                    }
                    .disabled(item.isDownloaded)
                }
            } else if item.compressionState == .pending{
                Text("Waiting for compression")
                    .foregroundColor(.red)
            } else if item.compressionState == .failed {
                Text("Compression failed")
                    .foregroundColor(.red)
            } else if item.compressionState == .compressing{
                ProgressView("")
                    .scaleEffect(0.5)
                    .labelsHidden()
            } else {
                // 否则，显示加载状态。
                ProgressView("")
                    .scaleEffect(0.5)
                    .labelsHidden()
            }
            
        }
    }
}

#Preview {
    ZStack {
        Color.white.frame(width: 300,height:40)
        ImageRowView(item: CustomImages(image: NSImage(named: "upload")!, name: "ooPAPiDIMwAoiDvPFIs7CZIAcyAqEyAgzB5gQ.webp", type: "PNG", inputSize: 1200000,outputSize: 840000,outputURL: URL(string: "http://www.fangjunyu.com"),compressionState: .completed), index: 0, previewer: ImagePreviewWindow())
            .frame(width: 300,height:40)
        // .environment(\.locale, .init(identifier: "de")) // 设置为德语
    }
}
