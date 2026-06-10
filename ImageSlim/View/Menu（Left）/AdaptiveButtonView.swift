//
//  AdaptiveButtonView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/8/25.
//
//  自适用按钮视图
//

import SwiftUI

enum DownloadStatus {
    case download
    case loading
    case complete
    case error
}

struct AdaptiveButtonView: View {
    @EnvironmentObject var appStorage: AppStorage
    @EnvironmentObject var imageArray: ImageArrayViewModel
    var workSpaceVM = WorkSpaceViewModel.shared
    @State var progress = 0.0
    @State var downloadsStatus: DownloadStatus = .download
    
    // 图片列表
    var images: [CustomImages] {
        if appStorage.selectedView == .compression {
            imageArray.compressedImages
        } else if appStorage.selectedView == .conversion {
            imageArray.conversionImages
        } else {
            []
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // MARK: 清除队列按钮
            // 如果图片列表不为空，则显示清除队列按钮
            if !images.isEmpty {
                clearButton
            } else {
                Color.clear.frame(width: 120,height:35)
                    .opacity(0)
            }
            
            // MARK: 下载图片按钮
            // 用户未完成内购，图片列表不为空，图片列表中有小于5MB的图片
            // 或者用户完成内购，图片不为空
            // 满足以上任一条件，显示下载和清除队列按钮
            if (!appStorage.inAppPurchaseMembership && images.contains { $0.inputSize < imageArray.limitImageSize }) ||
                (appStorage.inAppPurchaseMembership && !images.isEmpty) {
                // 下载全部
                downloadButton
            } else {
                Color.clear.frame(width: 120,height:35)
                    .opacity(0)
            }
        }
        .padding(10)
    }
    
    var clearButton: some View {
        Button(action: {
            removeImages()
        }, label: {
            ZStack {
                Rectangle()
                    .frame(width: 120,height: 35)
                    .foregroundColor(Color(hex: "FF4343"))
                    .cornerRadius(10)
                Text("Clear Queue")
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5) // 最多缩小到原始字体大小的 50%
            }
        })
        .buttonStyle(.plain)
        .modifier(HoverModifier())
    }
    
    var downloadButton: some View {
        Button(action: {
            Task {
                FileUtils.zipImages(isPurchase:appStorage.inAppPurchaseMembership, limitImageSize: imageArray.limitImageSize,keepOriginalFileName: appStorage.keepOriginalFileName,images: images,downloadsStatus: $downloadsStatus,progress: $progress)
                
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                
                downloadsStatus = .download
            }
        }, label: {
            ZStack {
                switch downloadsStatus {
                    
                    // 下载全部
                case .download:
                    Rectangle()
                        .frame(width: 120,height: 35)
                        .foregroundColor(Color(hex: "3960EA"))
                        .cornerRadius(10)
                    Text("Download All")
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5) // 最多缩小到原始字体大小的 50%
                    
                    // 下载中
                case .loading:
                    Rectangle()
                        .frame(width: 120,height: 35)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width:100,height:35)
                    
                    // 下载完成
                case .complete:
                    Rectangle()
                        .frame(width: 120,height: 35)
                        .foregroundColor(Color(hex: "CC7C5E"))
                        .cornerRadius(10)
                        Text("Saved")
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5) // 最多缩小到原始字体大小的 50%
                    
                    // 下载失败
                case .error:
                    Rectangle()
                        .frame(width: 120,height: 35)
                        .foregroundColor(Color.gray)
                        .cornerRadius(10)
                    Text("Download Failed")
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5) // 最多缩小到原始字体大小的 50%
                }
            }
        })
        .buttonStyle(.plain)
        .modifier(HoverModifier())
    }
    
    func removeImages() {
        if appStorage.selectedView == .compression {
            // 移除显示压缩图片和压缩图片任务队列中的图片
            imageArray.cancelCompressionTask()
        } else {
            // 移除转换图片和转换图片任务队列中的图片
            imageArray.cancelConversionTask()
        }
    }
}
