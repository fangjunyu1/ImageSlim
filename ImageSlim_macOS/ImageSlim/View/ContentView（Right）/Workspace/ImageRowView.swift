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
    @State private var hovering = false
    @EnvironmentObject var appStorage: AppStorage
    @EnvironmentObject var workSpaceVM: WorkSpaceViewModel
    @EnvironmentObject var imageArray: ImageArrayViewModel
    @ObservedObject var item: CustomImages
    @State private var shakeOffset: CGFloat = 0
    var imageType: WorkTaskType
    let rightButtonWidth = 70.0
    let rightButtonHeight = 30.0
    
    var body: some View {
        HStack {
            ZStack {
                if let thumbnail = item.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 35, height: 35)
                }
                Group {
                    Color.gray.opacity(0.3)
                    Image(systemName:"plus.magnifyingglass")
                        .foregroundColor(.white)
                        .allowsHitTesting(false)
                }
                .frame(width: 35, height: 35)
                .zIndex(hovering ? 1 : -1)
            }
            // 悬停显示放大按钮
            .onTapGesture {
                lookImg()
            }
            .onHover { isHovering in
                // 当鼠标进入视图区域时 isHovering = true
                // 当鼠标离开视图区域时 isHovering = false
                if isHovering {
                    hovering = true
                } else {
                    hovering = false
                }
            }
            .modifier(HoverModifier())
            .cornerRadius(4)
            
            Spacer().frame(width:20)
            // 图片信息
            VStack(alignment: .leading) {
                // 图片名称
                Text("\(item.fullName)")
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
                        Text("\(item.inputType)")
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    let isOverLimit = !appStorage.inAppPurchaseMembership && item.inputSize > imageArray.limitImageSize
                    Text(FileUtils.TranslateSize(fileSize: item.inputSize))
                        .foregroundColor(isOverLimit ? .red : .gray)
                }
            }
            Spacer()
            
            // 如果图片完成压缩，显示压缩图片的输出参数和下载按钮
            if item.isState == .completed {
                // 根据图片的类型，显示压缩/转换的图片视图
                if imageType == .compression {
                    VStack(alignment: .trailing) {
                        // 压缩占比
                        Text("-\(Int((item.compressionRatio) * 100))%")
                        Spacer().frame(height:3)
                        // 输出图片大小
                        Text(FileUtils.TranslateSize(fileSize:item.outputSize))
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                } else if imageType == .conversion {
                    VStack(alignment: .trailing) {
                        // 压缩占比
                        ZStack {
                            Rectangle()
                                .foregroundColor(colorScheme == .light ? .purple : Color(hex: "2f2f2f"))
                                .frame(width:50,height:16)
                                .cornerRadius(3)
                            Text("\(item.outputType)")
                                .font(.footnote)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                        Spacer().frame(height:3)
                        // 输出图片大小
                        Text(FileUtils.TranslateSize(fileSize:item.outputSize))
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer().frame(width:10)
                
                // 赞助应用，显示下载按钮，未赞助应用，超过5MB的图片显示 锁图标
                if !appStorage.inAppPurchaseMembership && item.inputSize > imageArray.limitImageSize {
                    VStack {
                        Image(systemName:"lock.fill")
                            .offset(x: shakeOffset)
                    }
                    .modifier(ImageRowViewButton(rightButtonWidth: rightButtonWidth,rightButtonHeight: rightButtonHeight))
                    .modifier(HoverModifier())
                    .onTapGesture {
                        print("抖动锁图标")
                        triggerShake()
                    }
                    .cornerRadius(20)
                } else {
                    // 下载按钮
                    Button(action: {
                        // 修改下载标识
                        item.isDownload = .running
                        Task { @MainActor in
                            let result = FileUtils.saveToDownloads(file: item)
                            if result {
                                // 首次下载完成，弹出评分弹窗
                                FileUtils.requestRating()
                                print("保存成功，修改Download状态")
                                item.isDownload = .complete
                                // 延时 3 秒后恢复
                            } else {
                                print("保存失败，修改Download状态")
                                item.isDownload = .failed
                            }
                            try await Task.sleep(nanoseconds: 3_000_000_000)
                            print("恢复下载标识")
                            // 恢复下载标识
                            item.isDownload = .idle
                        }
                    }) {
                        if item.isDownload == .complete {
                            // 下载完成标识
                            Image(systemName:"checkmark")
                                .modifier(ImageRowViewButton(rightButtonWidth: rightButtonWidth,rightButtonHeight: rightButtonHeight))
                        } else if item.isDownload == .idle {
                            // 可下载标识
                            Text("Download")
                                .modifier(ImageRowViewButton(rightButtonWidth: rightButtonWidth,rightButtonHeight: rightButtonHeight))
                        } else if item.isDownload == .running {
                            // 下载中标识
                            ProgressView("")
                                .scaleEffect(0.5)
                                .labelsHidden()
                                .modifier(ImageRowViewButton(rightButtonWidth: rightButtonWidth,rightButtonHeight: rightButtonHeight))
                        } else if item.isDownload == .failed {
                            // 下载错误标识
                            Image(systemName:"xmark")
                                .modifier(ImageRowViewButton(rightButtonWidth: rightButtonWidth,rightButtonHeight: rightButtonHeight))
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(item.isDownload != .idle)
                }
                
            } else if item.isState == .pending{
                if imageType == .compression {
                    tipState(name: "Waiting for compression")
                } else if imageType == .conversion {
                    tipState(name: "Waiting for conversion")
                }
                
            } else if item.isState == .failed {
                if imageType == .compression {
                    tipState(name: "Compression failed")
                } else if imageType == .conversion {
                    tipState(name: "Conversion failed")
                }
            } else if item.isState == .running {
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

private struct ImageRowViewButton: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let rightButtonWidth: Double
    let rightButtonHeight: Double
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .foregroundColor(colorScheme == .light ? Color(hex: "3679F6") : .white)
            .frame(width: rightButtonWidth,height: rightButtonHeight)
            .background(colorScheme == .light ? Color(hex: "EEEEEE") : Color(hex: "555555"))
            .cornerRadius(20)
    }
}

private struct tipState: View {
    var name: String
    var body: some View {
        Text(LocalizedStringKey(name))
            .foregroundColor(.red)
    }
}
extension ImageRowView {
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
    
    func lookImg() {
        // 根据 AppStorage 选项，选择图片打开方式：
        if appStorage.imagePreviewMode == .quickLook {
            // 使用 Quick Look 预览图片
            FileUtils.previewImage(at: item.inputURL)
        } else if appStorage.imagePreviewMode == .window {
            // 使用新窗口预览图片
            let fullImage = item.loadImageIfCalculate()
            guard let img = fullImage else { return }
            ImagePreviewWindow.shared.show(image: img)
        }
    }
}

#Preview {
    ZStack {
        Color.white.frame(width: 300,height:40)
        ImageRowView(item:
                        CustomImages(id: UUID(), name: "1", type: .conversion, inputURL: URL("https://backend.chatbase.co/storage/v1/object/public/chat-icons/72529423-6fcb-41de-ba3f-5f78df0223dd/yvyyk1zKYArY67zEfPZ6J.webp")!, inputType: "PNG", outputType: "PNG", isState: .completed),
                     imageType: .conversion)
        .frame(width: 300,height:40)
        .environmentObject(AppStorage.shared)
        .environmentObject(WorkSpaceViewModel.shared)
        .environmentObject(ImageArrayViewModel.shared)
        // .environment(\.locale, .init(identifier: "de")) // 设置为德语
        .onAppear {
            print("\(CustomImages.isPreview ? "预览模式" : "正式环境")")
        }
    }
    .frame(width: 350,height: 100)
}
