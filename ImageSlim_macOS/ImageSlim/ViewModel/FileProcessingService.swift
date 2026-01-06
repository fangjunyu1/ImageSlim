//
//  FileProcessingService.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/5.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
class FileProcessingService: ObservableObject {
    static var shared = FileProcessingService()
    var appStorage = AppStorage.shared
    var workSpaceVM = WorkSpaceViewModel.shared
    var imageArray = ImageArrayViewModel.shared
    private init() {}
    
    private func getLimitedURLs(for type: WorkspaceType) -> [URL] {
        let currentCount = type == .compression ?
        imageArray.compressedImages.count :
        imageArray.conversionImages.count
        return []
    }
    
    // MARK: 拖入图片执行代码
    func onDrop(type: WorkspaceType,providers:[NSItemProvider]) async {
        var imagesCount: Int {
            switch type {
            case .compression:
                imageArray.compressedImages.count
            case .conversion:
                imageArray.conversionImages.count
            }
        }
        // 判断是否限制图片数量
        let islimitImagesNum = appStorage.inAppPurchaseMembership ? false : true
        
        print("当前图片数量:\(imagesCount)，队列图片数量:\(imageArray.compressTaskQueue.count)")
        // 限制数量，默认限制数量为20，计算可用的数量：限制数量 - 当前图片数量 = 可以放入图片队列的数量
        let limitNum =  imageArray.limitImageNum - imagesCount
        print("限制数量：\(limitNum)")
        
        
        
        // 根据限制数量，截取遍历的有效图片数组
        let effectiveProviders = islimitImagesNum
        ? Array(providers.prefix(limitNum))
        : providers
        
        // 图片 URL 列表，用于返回并添加到对应 压缩/转换 的队列
        var imageURLs: [URL] = []
        
        // 进入 withTaskGroup（TaskGroup）
        await withTaskGroup(of: URL?.self) { group in
            // 遍历每一个图片
            for provider in effectiveProviders {
                // 检测类型是否为图片
                guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
                    continue
                }
                group.addTask {
                    // 桥接 TaskGroup 和 loadFileRepresentation 回调闭包，将 loadFileRepresentation 回调闭包的值返回给 addTask
                    await withCheckedContinuation { cont in
                        provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                            
                            // 错误场景：返回nil
                            guard let fileURL = url else {
                                cont.resume(returning: nil)
                                return
                            }
                            
                            // 成功场景:返回图片 URL
                            let imageURL = FileUtils.saveURLToTempFile(fileURL: fileURL)
                            cont.resume(returning: imageURL)
                        }
                    }
                }
            }
            
            for await url in group {
                if let url = url {
                    imageURLs.append(url)
                }
            }
        }
        
        // 调用闭包，将图片URL数组传递进入
        switch type {
        case .compression:
            WorkSpaceViewModel.shared.saveCompressPictures(url: imageURLs)
        case .conversion:
            WorkSpaceViewModel.shared.saveConversionPictures(url: imageURLs)
        }
    }
    
    func fileImporter(type: WorkspaceType,result: Result<[URL], any Error>) {
        
        var imagesCount: Int {
            switch type {
            case .compression:
                imageArray.compressedImages.count
            case .conversion:
                imageArray.conversionImages.count
            }
        }
        
        guard case let .success(urls) = result else {
            print("导入文件失败")
            return
        }
        let selectedFiles: [URL] = urls
        
        // 判断是否限制图片数量
        let islimitImagesNum = appStorage.inAppPurchaseMembership ? false : true
        // 限制数量，默认限制数量为20，计算可用的数量：限制数量 - 当前图片数量 = 可以放入图片队列的数量
        let limitNum =  imageArray.limitImageNum - imagesCount
        
        // 根据限制数量，截取遍历的有效图片数组
        let effectiveFiles = islimitImagesNum
        ? Array(selectedFiles.prefix(limitNum))
        : selectedFiles
        
        // 图片 URL 列表，用于返回并添加到对应 压缩/转换 的队列
        var imageURLs: [URL] = []
        
        // 沙盒权限权限请求
        for selectedFile in effectiveFiles {
            guard selectedFile.startAccessingSecurityScopedResource() else {
                print("无文件访问权限")
                return
            }
            defer { selectedFile.stopAccessingSecurityScopedResource() }
            // 根据 fileURL 保存图像
            guard let fileURL = FileUtils.saveURLToTempFile(fileURL: selectedFile) else { return }
            print("插入一张图片")
            imageURLs.append(fileURL)
        }
        
        switch type {
        case .compression:
            WorkSpaceViewModel.shared.saveCompressPictures(url: imageURLs)
        case .conversion:
            WorkSpaceViewModel.shared.saveConversionPictures(url: imageURLs)
        }
    }
    
    func onReceive(type: WorkspaceType) {
        print("支持的格式有：\(NSPasteboard.general.types ?? [])")
        
        let pb = NSPasteboard.general
        
        // 图片 URL 列表，用于返回并添加到对应 压缩/转换 的队列
        var imageURLs: [URL] = []
        
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            var imagesCount: Int {
                switch type {
                case .compression:
                    imageArray.compressedImages.count
                case .conversion:
                    imageArray.conversionImages.count
                }
            }
            // 判断是否限制图片数量
            let islimitImagesNum = appStorage.inAppPurchaseMembership ? false : true
            // 限制数量，默认限制数量为20，计算可用的数量：限制数量 - 当前图片数量 = 可以放入图片队列的数量
            let limitNum =  imageArray.limitImageNum - imagesCount
            
            // 根据限制数量，截取遍历的有效图片数组
            let effectiveProviders = islimitImagesNum
            ? Array(urls.prefix(limitNum))
            : urls
            
            // 读取urls文件
            for url in effectiveProviders {
                // 获取 Finder 上的大小
                let fileSize = FileUtils.getFileSize(fileURL: url)
                
                let imageName = url.lastPathComponent
                let imageType = url.pathExtension.uppercased()
                
                var compressionState: CompressionState = .pending
                
                if !appStorage.inAppPurchaseMembership && fileSize >  imageArray.limitImageSize {
                    print("文件过大跳过:\(imageName),文件大小为:\(fileSize)")
                    compressionState = .failed
                }
                print("当前内购状态:\(appStorage.inAppPurchaseMembership),fileSize:\(fileSize)")
                // 内购用户 or 文件大小合规
                let customImage = CustomImages(
                    name: imageName,
                    inputType: imageType,
                    inputSize: fileSize,
                    inputURL: url,
                    compressionState: compressionState
                )
                
                imageArray.compressedImages.append(customImage)
                
                switch type {
                case .compression:
                    WorkSpaceViewModel.shared.saveCompressPictures(url: imageURLs)
                case .conversion:
                    WorkSpaceViewModel.shared.saveConversionPictures(url: imageURLs)
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
                
                let imageName = url.lastPathComponent
                let imageType = url.pathExtension.uppercased()
                
                var compressionState: CompressionState = .pending
                
                if !appStorage.inAppPurchaseMembership && fileSize >  imageArray.limitImageSize {
                    print("文件过大跳过:\(imageName),文件大小为:\(fileSize)")
                    compressionState = .failed
                }
                print("当前内购状态:\(appStorage.inAppPurchaseMembership),fileSize:\(fileSize)")
                // 内购用户 or 文件大小合规
                let customImage = CustomImages(
                    name: imageName,
                    inputType: imageType,
                    inputSize: fileSize,
                    inputURL: url,
                    compressionState: compressionState
                )
                
                imageArray.compressedImages.append(customImage)
                
                switch type {
                case .compression:
                    WorkSpaceViewModel.shared.saveCompressPictures(url: imageURLs)
                case .conversion:
                    WorkSpaceViewModel.shared.saveConversionPictures(url: imageURLs)
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
    }
}
