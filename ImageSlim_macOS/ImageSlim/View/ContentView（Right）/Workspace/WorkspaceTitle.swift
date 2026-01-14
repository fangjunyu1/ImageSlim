//
//  WorkspaceTitle.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/2.
//

import SwiftUI

struct WorkspaceTitle: View {
    @EnvironmentObject var appStorage: AppStorage
    var type: WorkTaskType
    var isHovering: Bool
    var body: some View {
        switch type {
        case .compression:
            if isHovering {
                // 释放文件，添加压缩
                Text("Release the file and add compression")
                    .font(.title)
            } else {
                // 上传图片，即刻压缩
                Text("Upload pictures and compress them instantly")
                    .font(.title)
            }
        case .conversion:
            if isHovering {
                Text("Free files and convert them immediately")
                    .font(.title)
            } else {
                HStack {
                    Text("Converting images")
                        .font(.title)
                    Menu {
                        ForEach(ConversionTypeState.allCases) { option in
                            Button(option.rawValue) {
                                appStorage.convertTypeState = option
                            }
                        }
                    } label: {
                        Text(appStorage.convertTypeState.rawValue.uppercased())
                            .frame(width: 60, height: 30)
                            .foregroundColor(.white)
                            .background(Color(hex: "082A7C"))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .frame(height: 25)
                    .modifier(HoverModifier())
                }
            }
        }
    }
}

#Preview {
    WorkspaceTitle(type: .conversion, isHovering: true)
        .environmentObject(AppStorage.shared)
}
