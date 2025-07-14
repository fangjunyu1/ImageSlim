//
//  ImageRowView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/12.
//

import SwiftUI
import QuickLookUI

struct ImageRowView: View {
    @State private var hoveringIndex: Int? = nil
    @ObservedObject var appStorage = AppStorage.shared
    @ObservedObject var compressManager = CompressionManager.shared
    @ObservedObject var item: CustomImages
    var index: Int
    var previewer: ImagePreviewWindow
    // var completion: () -> Void
    
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
    
    // 下载图片到 Downloads 文件夹
    func saveToDownloads(file: CustomImages) {
        var directory:FileManager.SearchPathDirectory {
            switch appStorage.imageSaveDirectory {
            case .downloadsDirectory:
                return .downloadsDirectory
            case .picturesDirectory:
                return .picturesDirectory
            }
        }
        let directoryURL = FileManager.default.urls(for: directory, in: .userDomainMask).first!
        let destinationURL = directoryURL.appendingPathComponent(file.name)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            if let outURL = file.outputURL {
                try FileManager.default.copyItem(at: outURL, to: destinationURL)
            }
            print("已保存到 \(directory) 目录：\(destinationURL.path)")
        } catch {
            print("保存失败：\(error)")
        }
    }
    // 根据图片的字节大小显示适配的存储大小。
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
                            .foregroundColor(Color(hex: "91C9FF"))
                            .frame(width:50,height:16)
                            .cornerRadius(3)
                        Text("\(item.type)")
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    Text(TranslateSize(fileSize:item.inputSize))
                        .foregroundColor(.gray)
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
                            .foregroundColor(Color(hex: "3679F6"))
                            .padding(.vertical,5)
                            .padding(.horizontal,20)
                            .background(Color(hex: "EEEEEE"))
                            .cornerRadius(20)
                    } else {
                        Text("Download")
                            .foregroundColor(Color(hex: "3679F6"))
                            .padding(.vertical,5)
                            .padding(.horizontal,20)
                            .background(Color(hex: "EEEEEE"))
                            .cornerRadius(20)
                    }
                }
                .frame(width: 70)
                .buttonStyle(.plain)
                .onHover { isHovering in
                    isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                }
                .disabled(item.isDownloaded)
            } else if item.compressionState == .pending{
                Text("等待压缩")
                    .foregroundColor(.red)
            } else if item.compressionState == .failed {
                Text("压缩失败")
                    .foregroundColor(.red)
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
    ImageRowView(item: CustomImages(image: NSImage(named: "upload")!, name: "ooPAPiDIMwAoiDvPFIs7CZIAcyAqEyAgzB5gQ.webp", type: "PNG", inputSize: 1200000,outputSize: 120000,outputURL: URL(string: "http://www.fangjunyu.com"),compressionState: .completed), index: 0, previewer: ImagePreviewWindow())
        .frame(width: 300,height:40)
}
