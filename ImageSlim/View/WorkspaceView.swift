//
//  WorkspaceView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import SwiftUI

struct WorkspaceView: View {
    @ObservedObject var compressImages = CompressImagesData.shared
    var body: some View {
        if compressImages.selectedView == .compression {
            CompressionView()
        } else if compressImages.selectedView == .settings {
            SettingsView()
        } else {
            
        }
    }
}

#Preview {
    WorkspaceView()
}
