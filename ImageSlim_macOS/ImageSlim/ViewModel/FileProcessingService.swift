//
//  FileProcessingService.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/5.
//
//  用于处理拖入、导入、粘贴的图片方法
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
    
    // 返回可用的泛型数组
    private func getLimitedArray<T>(from array: [T], for type: WorkTaskType) -> [T] {
        // 根据类型获取对应的压缩/转换图片数组的数量
        let currentCount = type == .compression ?
        imageArray.compressedImages.count :
        imageArray.conversionImages.count
        
        // 内购用户，返回所有 URL，非内购用户，继续执行
        if appStorage.inAppPurchaseMembership {
            return array
        }
        
        // 返回可用总数
        let availableCount = max(0, imageArray.limitImageNum - currentCount)
        return Array(array.prefix(availableCount))
    }
    
    // 传入 URL，返回 CustomImages 对象
    nonisolated private func createCustomImages(type: WorkTaskType, url: URL, outputType: String) -> CustomImages {
        print("进入 createCustomImages 方法")
        // 设置 CustomImages 的 UUID，也是临时文件的名称
        let uuid = UUID()
        // 获取 URL 图片的文件名称
        let imageName = (url.lastPathComponent as NSString).deletingPathExtension
        // 获取 URL 图片的类型字符串（大写）
        let inputType = url.pathExtension.uppercased()
        
        // 设置临时图片的保存路径并尝试保存
        let fileManager = FileManager.default
        let tmpExtension = url.pathExtension.lowercased()
        let tmpURL = fileManager.temporaryDirectory
            .appendingPathComponent("\(uuid)")
            .appendingPathExtension(tmpExtension)
        
        // 防止存在旧文件（尽管可能性不大）
        try? fileManager.removeItem(at: tmpURL)
        
        // 将 url 保存到临时文件中
        do {
            try fileManager.copyItem(at: url, to: tmpURL)
        } catch {
            print("图片拷贝失败")
            print("原始文件 URL:\(url)")
            print("拷贝临时文件夹的 URL:\(tmpURL)")
        }
        
        // 创建 CustomImages 对象
        let customImages = CustomImages(
            id: uuid,
            name: imageName,
            type: type,
            inputURL: tmpURL,
            inputType: inputType,
            outputType: outputType)
        
        return customImages
    }
}

extension FileProcessingService {
    
    // MARK: 拖入图片执行代码
    func onDrop(type: WorkTaskType,providers:[NSItemProvider]) async {
        
        let outputType = appStorage.convertTypeState.rawValue
        
        // 获取可用的 NSItemProvider 数组
        let limitProviders = getLimitedArray(from: providers, for: type)
        
        // TaskGroup 可以实现 I/O 并行排队执行
        await withTaskGroup(of: CustomImages?.self) { group in
            
            // 遍历每一个图片
            for provider in limitProviders {
                // 检测类型是否为图片
                guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
                    continue
                }
                
                // 添加并发子任务
                group.addTask {
                    // 返回拖入的图片，并创建 CustomImages 对象
                    return await withCheckedContinuation { cont in
                        provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { loadUrl, error in
                            print("进入 loadFileRepresentation 方法")
                            // 当 url 为 nil 时，返回 nil
                            guard let url = loadUrl else {
                                print("url失败")
                                cont.resume(returning:nil)
                                return
                            }
                            
                            // 当 url 不为 nil， 则创建 CustomImages 对象
                            let customImages = self.createCustomImages(type: type,url: url,outputType: outputType)
                            cont.resume(returning: customImages)
                        }
                    }
                }
            }
            
            // 获取所有的 CustomImage 对象，并插入显示队列，执行队列任务
            for await image in group {
                imageArray.addViewQueue(type: type,image: image)
            }
        }
    }
}

extension FileProcessingService {
    
    // MARK: 导入图片
    func fileImporter(type: WorkTaskType,result: Result<[URL], Error>) async {
        let outputType = appStorage.convertTypeState.rawValue
        guard case let .success(urls) = result else {
            print("导入文件失败")
            return
        }
        
        // 获取可用的 NSItemProvider 数组
        let limitProviders = getLimitedArray(from: urls, for: type)
        
        // TaskGroup 可以实现 I/O 并行排队执行
        await withTaskGroup(of: CustomImages?.self) { group in
            
            // 沙盒权限权限请求
            for url in limitProviders {
                guard url.startAccessingSecurityScopedResource() else {
                    print("无文件访问权限")
                    continue
                }
                group.addTask {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // 当 url 不为 nil， 则创建 CustomImages 对象
                    let customImages = self.createCustomImages(type: type, url: url,outputType: outputType)
                    return customImages
                }
            }
            
            // 获取所有的 CustomImage 对象，并插入显示队列，执行队列任务
            for await image in group {
                imageArray.addViewQueue(type: type,image: image)
            }
        }
    }
}

extension FileProcessingService {
    
    // MARK: Command + V 粘贴
    func onReceive(type: WorkTaskType) async {
        let outputType = appStorage.convertTypeState.rawValue
        let pb = NSPasteboard.general
        
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            
            // 获取可用的 NSItemProvider 数组
            let limitProviders = getLimitedArray(from: urls, for: type)
            
            // TaskGroup 可以实现 I/O 并行排队执行
            await withTaskGroup(of: CustomImages?.self) { group in
                
                // 读取urls文件
                for url in limitProviders {
                    group.addTask {
                        self.createCustomImages(type: type, url: url,outputType: outputType)
                    }
                }
                
                // 获取所有的 CustomImage 对象，并插入显示队列，执行队列任务
                for await image in group {
                    imageArray.addViewQueue(type: type,image: image)
                }
            }
        } else if let imageData = pb.data(forType: .tiff) {
            
            // 粘贴的图片为照片，图片格式默认为 png 格式
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
            
            do {
                try imageData.write(to: url)
                let customImage = createCustomImages(type: type, url: url,outputType: outputType)
                imageArray.addViewQueue(type: type,image: customImage)
                
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

extension FileProcessingService {
    
    // MARK: 右键接收文件
    func fileImporter(_ urls: [URL]) async {
        
        // 输出图片格式
        let outputType = appStorage.convertTypeState.rawValue
        
        // 获取可用的 NSItemProvider 数组
        let limitProviders = getLimitedArray(from: urls, for: .compression)
        
        // TaskGroup 可以实现 I/O 并行排队执行
        await withTaskGroup(of: CustomImages?.self) { group in
            
            // 沙盒权限权限请求
            for url in limitProviders {
                guard url.startAccessingSecurityScopedResource() else {
                    print("无文件访问权限")
                    continue
                }
                group.addTask {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // 当 url 不为 nil， 则创建 CustomImages 对象
                    let customImages = self.createCustomImages(type: .compression, url: url,outputType: outputType)
                    return customImages
                }
            }
            
            // 获取所有的 CustomImage 对象，并插入显示队列，执行队列任务
            for await image in group {
                imageArray.addViewQueue(type: .compression,image: image)
            }
        }
    }
    
}
