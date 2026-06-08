//
//  WorkspaceZStack.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/2.
//

import SwiftUI

struct WorkspaceZStack: View {
    @Environment(\.colorScheme) var colorScheme
    
    var type: WorkTaskType
    var isHovering: Bool
    @Binding var showImporter: Bool
    
    // 占位符图片
    @State private var placeholderImage: NSImage?
    
    private let cardWidth: CGFloat = 240
    private let cardHeight: CGFloat = 160
    
    // 用户自定义的占位符文件名称
    private var placeholderFileName: String {
        switch type {
        case .compression:
            return AppStorage.compressionImageName
        case .conversion:
            return AppStorage.conversionImageName
        }
    }
    
    // 默认占位符文件名称
    private var defaultImageName: String {
        switch type {
        case .compression:
            return "upload"
        case .conversion:
            return "conversion"
        }
    }
    
    var body: some View {
        ZStack {
            // 如果用户有设置自定义的压缩图片占位符
            if let placeholderImage {
                Image(nsImage: placeholderImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                    .cornerRadius(5)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 4)
            } else {
                Rectangle()
                    .frame(width: cardWidth, height: cardHeight)
                    .foregroundColor(backgroundColor)
                    .cornerRadius(5)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 4)
                
                Image(defaultImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
            }
        }
        .contextMenu {
            Button(action: changePlaceholder) {
                Label("Change Placeholder…", systemImage: "photo")
            }
            
            Button(action: resetPlaceholder) {
                Label("Reset Placeholder", systemImage: "arrow.counterclockwise")
            }
        }
        .modifier(HoverModifier())
        .onTapGesture {
            showImporter = true
        }
        .onAppear {
            loadPlaceholder()
        }
    }
    
    // 默认占位符背景 - 悬浮时修改对应的背景颜色
    private var backgroundColor: Color {
        if isHovering {
            return colorScheme == .light
            ? Color(hex: "BEE2FF")
            : Color(hex: "3d3d3d")
        } else {
            return colorScheme == .light
            ? Color(hex: "E6E6E6")
            : Color(hex: "2f2f2f")
        }
    }
    
    // 读取图片占位符
    private func loadPlaceholder() {
        guard iCloudFileManager.shared.isContainImagePlaceholder(fileName: placeholderFileName) else {
            placeholderImage = nil
            return
        }
        
        do {
            let data = try iCloudFileManager.shared.read(fileName: placeholderFileName)
            print("读取自定义图片占位符成功")
            placeholderImage = NSImage(data: data)
        } catch {
            print("读取自定义图片占位符失败：\(error.localizedDescription)")
            placeholderImage = nil
        }
    }
    
    // 更换图片占位符
    private func changePlaceholder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Image"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        
        let response = panel.runModal()
        
        guard response == .OK, let url = panel.url else {
            print("用户取消选择图片")
            return
        }
        
        guard let image = NSImage(contentsOf: url) else {
            print("图片转换为 NSImage 失败")
            return
        }
        
        saveUserImageToiCloud(image: image, name: placeholderFileName)
        loadPlaceholder()
    }
    
    // 重置占位符图片
    private func resetPlaceholder() {
        iCloudFileManager.shared.clear(fileName: placeholderFileName)
        placeholderImage = nil
    }
    
    // 保存自定义图片占位符
    private func saveUserImageToiCloud(image: NSImage, name imageName: String) {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            print("NSImage 转换为 JPEG Data 失败")
            return
        }
        
        do {
            try iCloudFileManager.shared.save(
                data: data,
                fileName: imageName
            )
            print("图片占位符已保存到 iCloud")
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }
}

#Preview {
    WorkspaceZStack(type: .conversion, isHovering: true, showImporter: .constant(true))
        .environmentObject(AppStorage.shared)
}
