//
//  ImageRowView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/12.
//

import SwiftUI
import QuickLookUI

enum ImageRowType {
    case compression
    case conversion
}

struct ImageRowView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var hovering = false
    @EnvironmentObject var appStorage: AppStorage
    @EnvironmentObject var workSpaceVM: WorkSpaceViewModel
    @EnvironmentObject var imageArray: ImageArrayViewModel
    var item: CustomImages
    @State private var shakeOffset: CGFloat = 0
    var previewer: ImagePreviewWindow
    var imageType: ImageRowType
    
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
                        Text("\(item.inputType)")
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    if !appStorage.inAppPurchaseMembership && item.inputSize > imageArray.limitImageSize {
                        Text(FileUtils.TranslateSize(fileSize:item.inputSize))
                            .foregroundColor(.red)
                    } else {
                        Text(FileUtils.TranslateSize(fileSize:item.inputSize))
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            
            // 如果图片完成压缩，显示压缩图片的输出参数和下载按钮
            if item.compressionState == .completed {
                if imageType == .compression {
                    VStack(alignment: .trailing) {
                        // 压缩占比
                        Text("-\(Int((item.compressionRatio ?? 0) * 100))%")
                        Spacer().frame(height:3)
                        // 输出图片大小
                        Text(FileUtils.TranslateSize(fileSize:item.outputSize ?? 0))
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
                                            Text("\(item.outputType ?? "")")
                                                .foregroundColor(.white)
                                                .cornerRadius(5)
                                        }
                                        Spacer().frame(height:3)
                                        // 输出图片大小
                                        Text(FileUtils.TranslateSize(fileSize:item.outputSize ?? 0))
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                }
                
                Spacer().frame(width:10)
                
                // 赞助应用，显示下载按钮，未赞助应用，超过5MB的图片显示 锁图标
                if !appStorage.inAppPurchaseMembership && item.inputSize > imageArray.limitImageSize {
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
                    .modifier(HoverModifier())
                } else {
                    // 下载按钮
                    Button(action: {
                        FileUtils.saveToDownloads(file: item)
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
                    .modifier(HoverModifier())
                    .disabled(item.isDownloaded)
                }
            } else if item.compressionState == .pending{
                if imageType == .compression {
                    Text("Waiting for compression")
                        .foregroundColor(.red)
                } else if imageType == .conversion {
                    Text("Waiting for conversion")
                        .foregroundColor(.red)
                }
               
            } else if item.compressionState == .failed {
                if imageType == .compression {
                    Text("Compression failed")
                        .foregroundColor(.red)
                } else if imageType == .conversion {
                    Text("Conversion failed")
                        .foregroundColor(.red)
                }
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
            if let image = item.image,let url = FileUtils.saveImageToTempFile(image: image) {
                FileUtils.previewImage(at: url)
            }
        } else if appStorage.imagePreviewMode == .window {
            // 使用新窗口预览图片
            if let image = item.image {
                previewer.show(image: Image(nsImage: image))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.white.frame(width: 300,height:40)
        
        ImageRowView(item: CustomImages(name: "1.png", inputType: "PNG", inputSize: 1000, inputURL: URL(string: "http://www.fangjunyu.com")!, compressionState: .compressing), previewer: ImagePreviewWindow(), imageType: .compression)
            .frame(width: 300,height:40)
            .environmentObject(AppStorage.shared)
        // .environment(\.locale, .init(identifier: "de")) // 设置为德语
    }
    .frame(width: 350,height: 100)
}
