//
//  WorkSpaceViewModel.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/2.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
class WorkSpaceViewModel: ObservableObject {
    static var shared = WorkSpaceViewModel()
    var appStorage = AppStorage.shared
    private init() {}
    
    func onDrop(imagesCount: Int,providers:[NSItemProvider],savePicture: @escaping (_ imageURLs:[URL]) -> Void) -> Bool {
        print("进入 onDrop 方法")
        // 判断是否限制图片数量
        let islimitImagesNum = appStorage.inAppPurchaseMembership ? false : true
        // 限制数量，默认限制数量为20，计算可用的数量：限制数量 - 当前图片数量 = 可以放入图片队列的数量
        let limitNum = appStorage.limitImageNum - imagesCount
        
        // 根据限制数量，截取遍历的有效图片数组
        let effectiveProviders = islimitImagesNum
            ? Array(providers.prefix(limitNum))
            : providers
        
        // 图片 URL 列表，用于返回并添加到对应 压缩/转换 的队列
        var imageURLs: [URL] = []
        
        // 设置调度组，防止 loadFileRepresentation 异步任务立即返回的问题
        let group = DispatchGroup()
        
        // 拖拽返回的状态，默认为false，如果有效值，则改为true
        var accepted = false
        
        
        
        // 遍历每一个图片
        for provider in effectiveProviders {
            
            // 检测类型是否为图片
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                // 当前有图片，返回值改为true
                accepted = true
                
                print("进入组")
                group.enter()
                
                let syncQueue = DispatchQueue(label: "image.collect.queue")
                provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                    
                    // 如果解析图片报错，则输出错误
                    if let error = error {
                        print("loadFileRepresentation error:", error)
                    }
                    
                    defer {
                        print("离开组")
                        group.leave()
                    }
                    // 获取拖入图片的URL，将图片保存到临时文件
                    guard let fileURL = url,
                          let imageURL = FileUtils.saveURLToTempFile(fileURL: fileURL) else { return }
                    
                    // 将临时文件添加到数组中
                    syncQueue.async {
                        imageURLs.append(imageURL)
                    }
                }
            } else {
                print("当前类型不是图片")
                continue
            }
        }
        
        // 当全部组完成后执行
        group.notify(queue: .main) {
            // 调用闭包，将图片URL数组传递进入
            savePicture(imageURLs)
        }
        
        // 返回是否接受了拖入内容
        return accepted
    }
    
    func fileImporter(result: Result<[URL], any Error>,savePictures: @escaping (_ imageURLs:[URL]) -> Void) {
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
            
            savePictures(imageURLs)
        } catch {
            print("导入图片失败！")
        }
    }
    
    func onReceive(Enqueue: @escaping (_ images:[CustomImages]) -> Void) {
        print("支持的格式有：\(NSPasteboard.general.types ?? [])")
        let pb = NSPasteboard.general
        var images: [CustomImages] = []
        
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
                
                appStorage.compressedImages.append(customImage)
                
                if compressionState == .pending {
                    images.append(customImage)
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
                
                appStorage.compressedImages.append(customImage)
                
                if compressionState == .pending {
                    images.append(customImage)
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
        Enqueue(images)
    }
}

