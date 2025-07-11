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
import QuickLookUI
import AppKit

struct CompressionView: View {
    @State private var previewer = ImagePreviewWindow()
    @ObservedObject var appStorage = AppStorage.shared
    @State private var isHovering = false
    @State private var hoveringIndex: Int? = nil
    @State private var showImporter = false
    
    func previewImage(at url: URL) {
        
        guard let panel = QLPreviewPanel.shared() else { return }
        let dataSource = PreviewDataSource(urls: [url])
        panel.dataSource = dataSource
        panel.makeKeyAndOrderFront(nil)
    }
    
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
    
    func TranslateSize(fileSize: Int) -> String {
        let num = 1000.0
        let size = Double(fileSize)
        if size < num {
            return "\(size) B"
        } else if size < pow(num,2.0) {
            let sizeNum = size / pow(num,1.0)
            return "\(ceil(sizeNum.rounded())) KB"
        } else if size < pow(num,3.0) {
            let sizeNum = size / pow(num,2.0)
            return "\(String(format:"%.2f",sizeNum)) MB"
        } else if size < pow(num,4.0) {
            let sizeNum = size / pow(num,3.0)
            return "\(String(format:"%.2f",sizeNum)) GB"
        } else if size < pow(num,5.0) {
            let sizeNum = size / pow(num,4.0)
            return "\(String(format:"%.2f",sizeNum)) TB"
        } else {
            let sizeNum = num / pow(num,4.0)
            return "\(String(format:"%.2f",sizeNum)) TB"
        }
    }
    
    // 根据获取的 URL，存储图像
    func savePictures(url fileURL: URL) {
        let fileName = fileURL.lastPathComponent   // 文件名称
        let fileType = fileURL.pathExtension   // 文件类型
        
        // 获取 Finder 上的大小
        let resourceValues = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
        let DiskSize = resourceValues?.totalFileAllocatedSize ?? 0
        // 获取文件的实际大小
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int
        
        // 当macOS上有图像大小，以macOS上图像字节为准。
        // 如果macOS上没有图像大小，以获取的图像字节为准。
        let fileSize = DiskSize > 0 ? DiskSize : attributes ?? 0
        print("macOS显示的大小:\(DiskSize)")
        print("获取的文件实际大小:\(attributes ?? 0)")
        print("文件大小:\(fileSize)")
        
        if let nsImage = NSImage(contentsOf: fileURL) {
            DispatchQueue.main.async {
                let customImage = CustomImages(id: UUID(), image: nsImage, name: fileName, type: fileType.uppercased(), inputSize: fileSize)
                appStorage.images.append(customImage)
            }
        }
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
                        Text("Select up to 20 pictures, each no larger than 5MB.")
                            .font(.footnote)
                            .foregroundColor(.gray)
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
                            // 图片信息
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
                                    Text(TranslateSize(fileSize:item.inputSize))
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
                            .onHover { isHovering in
                                isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                            }
                            
                        }
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
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    print("图像类型")
                    provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                        guard let fileURL = url else {
                            print("获取文件失败: \(error?.localizedDescription ?? "未知错误")")
                            return
                        }
                        // 根据 fileURL 保存图像
                        savePictures(url: fileURL)
                    }
                }
            }
            // 处理 NSItemProvider 列表
            return true // 返回是否接受了拖入内容
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            // 处理选择结果
            do {
                let selectedFiles: [URL] = try result.get()
                
                // 沙盒权限权限请求
                for selectedFile in selectedFiles {
                    guard selectedFile.startAccessingSecurityScopedResource() else {
                        print("无文件访问权限")
                        return
                    }
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    // 根据 fileURL 保存图像
                    savePictures(url: selectedFile)
                }
            } catch {
                print("导入图片失败！")
            }
        }
        // 测试图片
        //        .onAppear {
        //            for i in 0...2 {
        //                let customImage = CustomImages(id: UUID(), image: NSImage(named:"upload")!, name: "测试", type: "png", inputSize: 3000)
        //                appStorage.images.append(customImage)
        //            }
        //        }
    }
}

#Preview {
    CompressionView()
}
