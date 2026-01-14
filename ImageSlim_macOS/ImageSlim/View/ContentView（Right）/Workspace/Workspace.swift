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

struct Workspace: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStorage: AppStorage
    @EnvironmentObject var imageArray: ImageArrayViewModel
    @StateObject var filePS = FileProcessingService.shared
    @StateObject var workSpaceVM = WorkSpaceViewModel.shared
    @State private var previewer = ImagePreviewWindow()
    @State private var isHovering = false   // 图片悬浮时
    @State private var showImporter = false
    var type: WorkTaskType
    
    var body: some View {
        var images: [CustomImages] {
            switch type {
            case .compression:
                imageArray.compressedImages
            case .conversion:
                imageArray.conversionImages
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
        .modifier(WindowsModifier())
        .environmentObject(workSpaceVM)
        // 拖入图片
        .onDrop(of: [.image], isTargeted: $isHovering) { providers in
            Task {
                await filePS.onDrop(type: type,providers: providers)
            }
            // 因为onDrop不支持async闭包，直接返回true
            return true
        }
        // 导入图片
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            Task {
                await filePS.fileImporter(type:type, result: result)
            }
        }
        // Command + V 粘贴图片
        .onReceive(KeyboardMonitor.shared.pastePublisher) { _ in
            Task {
                await filePS.onReceive(type: type)
            }
        }
        .onAppear {
            let tmpURL = FileManager.default.temporaryDirectory
            print("tmpURL:\(tmpURL)")
        }
    }
}

#Preview {
    Workspace(type: .compression)
        .environmentObject(AppStorage.shared)
}
