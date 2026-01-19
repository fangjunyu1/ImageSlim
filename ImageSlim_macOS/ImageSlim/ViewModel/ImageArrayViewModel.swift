//
//  ImageArrayViewModel.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/6.
//
//  管理应用压缩/转换的图片数组
//

import SwiftUI

@MainActor
class ImageArrayViewModel: ObservableObject {
    static let shared = ImageArrayViewModel()
    var appStorage = AppStorage.shared
    var workSpaceVM: WorkSpaceViewModel {
        WorkSpaceViewModel.shared
    }
    private init() {}
    
    // MARK: 压缩/转换配置
    // 非内购用户，限制 20 张图片
    @Published var limitImageNum = 20
    // 非内购用户，限制 5MB 图片
    @Published var limitImageSize = 5_000_000
    
    // MARK: 图片数组
    // 压缩图片数组
    @Published var compressedImages:[CustomImages] = []
    // 转换图片数组
    @Published var conversionImages:[CustomImages] = []
    
    // MARK: 任务队列
    // 任务队列：压缩图片数组
    @Published var compressTaskQueue: [CustomImages] = []
    // 任务队列：转换图片数组
    @Published var conversionTaskQueue: [CustomImages] = []
    
    // MARK: 状态标志
    // 当前有无被压缩的图片，isCompressing表示当前有图片被压缩，其他图片需要等待
    @Published var isCompressing = false
    // 当前有无被转换的图片，isCompressing = true，表示当前有图片被转换，其他图片需要等待
    @Published var isConversion = false
    
    // MARK: 添加图片到视图和队列
    @Published private var compressionTask: Task<Void, Never>?
    @Published private var conversionTask: Task<Void, Never>?
    
    //  MARK: 添加图片显示队列
    func addViewQueue(type: WorkTaskType,image: CustomImages?) {
        guard let image = image else { return }
        
        // 显示图片的缩略图和计算输入文件大小
        image.loadThumbnailIfNeeded() // 加载缩略图
        image.loadInputSizeIfNeeded() // 计算输入文件大小
        
        switch type {
        case .compression:
            // CustomImage 对象添加到视图的列表
            compressedImages.append(image)
        case .conversion:
            // CustomImage 对象添加到视图的列表
            conversionImages.append(image)
        }
        
        // 图片添加到压缩任务队列
        enqueueTask(type: type, image: image)
    }
    
    //  MARK: 插入并启动任务队列
    func enqueueTask(type: WorkTaskType, image: CustomImages) {
        
        // 将图片插入到压缩/转换的任务队列
        switch type {
        case .compression:
            compressTaskQueue.append(image)
        case .conversion:
            conversionTaskQueue.append(image)
        }
        
        // 启动串行任务队列
        startQueueTask(type: type)
    }
    
    // MARK: 启动任务队列
    func startQueueTask(type: WorkTaskType) {
        print("进入任务队列")
        // 如果任务为压缩/转换，对应状态为 true，表示任务进行中，不再重复启动
        switch type {
        case .compression:
            guard !isCompressing else {
                print("压缩任务进行中，新任务已加入队列")
                return
            }
            compressionTask = Task {
                await runQueueTask(type: type)
            }
        case .conversion:
            guard !isConversion else {
                print("转换任务进行中，新任务已加入队列")
                return
            }
            conversionTask = Task {
                await runQueueTask(type: type)
            }
        }
    }
    
    // MARK: While循环消费压缩/转换任务队列
    func runQueueTask(type: WorkTaskType) async {
        
        print("启动压缩/转换队列")
        
        // 进入函数时，修改压缩/转换标识
        switch type {
        case .compression:
            isCompressing = true
        case .conversion:
            isConversion = true
        }
        
        // 退出函数时，重置状态
        defer {
            print("队列没有任务，改为false")
            switch type {
            case .compression:
                isCompressing = false
            case .conversion:
                isConversion = false
            }
        }
        
        // 根据任务类型将对应的任务队列状态改为 true
        switch type {
        case .compression:
            while let task = compressTaskQueue.first {
                // 检查任务是否被取消
                if Task.isCancelled {
                    print("任务被取消")
                    return
                }
                
                print("开始转换\(task.fullName)")
                task.isState = .running // 更新图片的状态
                
                let result = await workSpaceVM.compressImage(task)
                if result {
                    task.isState = .completed
                    print("\(task.fullName) 压缩成功")
                } else {
                    task.isState = .failed
                    print("\(task.fullName) 压缩失败")
                }
                
                // 计算输出文件大小
                task.loadOutputSizeIfNeeded()
                // 释放图片
                task.releaseImage()
                // 移除已处理的任务
                compressTaskQueue.removeFirst()
                
                // 添加短暂延迟，避免 CPU 占比过高
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            
        case .conversion:
            while let task = conversionTaskQueue.first {
                // 检查任务是否被取消
                if Task.isCancelled {
                    print("任务被取消")
                    return
                }
                
                print("开始转换\(task.fullName)")
                task.isState = .running // 更新图片的状态
                
                let result = workSpaceVM.conversionImage(task)
                if result {
                    task.isState = .completed
                    print("\(task.fullName) 转换成功")
                    task.releaseImage() // 释放图片
                } else {
                    task.isState = .failed
                    print("\(task.fullName) 转换失败")
                }
                
                // 计算输出文件大小
                task.loadOutputSizeIfNeeded()
                // 释放图片
                task.releaseImage()
                // 移除已处理的任务
                conversionTaskQueue.removeFirst()
                
                // 添加短暂延迟，避免 CPU 占比过高
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
    
    func cancelAllTasks() {
        
        // 取消压缩任务
        cancelCompressionTask()
        // 取消转换任务
        cancelConversionTask()
        
        print("所有任务任务已取消")
    }
    
    // 取消所有的压缩任务
    func cancelCompressionTask() {
        compressionTask?.cancel()   // 取消压缩任务
        for i in compressedImages {
            i.releaseImage()
            i.releaseThumbnail()
        }
        compressedImages.removeAll()    // 移除压缩图片列表
        compressTaskQueue.removeAll()   // 移除压缩图片任务列表
        print("压缩任务已取消")
    }
    
    // 取消所有的转换任务
    func cancelConversionTask() {
        conversionTask?.cancel()   // 取消压缩任务
        for i in conversionImages {
            i.releaseImage()
            i.releaseThumbnail()
        }
        conversionImages.removeAll()    // 移除压缩图片列表
        conversionTaskQueue.removeAll()   // 移除压缩图片任务列表
        print("转换任务已取消")
    }
}
