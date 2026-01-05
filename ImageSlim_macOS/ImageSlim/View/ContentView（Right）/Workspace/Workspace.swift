//
//  Workspace.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/2.
//
//  压缩和转换视图

import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum WorkspaceType {
    case compression
    case conversion
}
struct Workspace: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStorage: AppStorage
    @StateObject var filePS = FileProcessingService.shared
    @StateObject var workSpaceVM = WorkSpaceViewModel.shared
    @State private var previewer = ImagePreviewWindow()
    @State private var isHovering = false   // 图片悬浮时
    @State private var showImporter = false
    var type: WorkspaceType
    
    var body: some View {
        var images: [CustomImages] {
            switch type {
            case .compression:
                appStorage.compressedImages
            case .conversion:
                appStorage.conversionImages
            }
        }
        VStack {
            AdaptiveContentView(isEmpty: images.isEmpty, title: {
                WorkspaceTitle(type: type, isHovering: isHovering)
            }, tips: {
                WorkspaceTips(type:type)
            }, zstack: {
                WorkspaceZStack(type: type, isHovering: isHovering,showImporter: $showImporter)
            }, list: {
                WorkspaceList(type: type, previewer: previewer)
            })
        }
        .environmentObject(compressManager)
        .environmentObject(conversionManager)
        .modifier(WindowsModifier())
        .onDrop(of: [.image], isTargeted: $isHovering) { providers in
            Task {
                await filePS.onDrop(type: type,providers: providers)
            }
            // 因为onDrop不支持async闭包，直接返回true
            return true
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            filePS.fileImporter(type:type, result: result)
        }
        .onReceive(KeyboardMonitor.shared.pastePublisher) { _ in
            filePS.onReceive() { compressImages in
                // for-in循环结束，开始调用压缩图片
                switch type {
                case .compression:
                    compressManager.enqueue(compressImages)
                case .conversion:
                    conversionManager.enqueue(compressImages)
                }
            }
        }
        
    }
}

#Preview {
    Workspace(type: .compression)
        .environmentObject(AppStorage.shared)
}
