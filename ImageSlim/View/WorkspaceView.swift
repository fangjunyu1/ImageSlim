//
//  WorkspaceView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import SwiftUI

struct WorkspaceView: View {
    @ObservedObject var tmpData = TemporaryData.shared
    var body: some View {
        if tmpData.selectedView == .compression {
            CompressionView()
        } else if tmpData.selectedView == .settings {
            SettingsView()
        } else {
            
        }
    }
}

#Preview {
    WorkspaceView()
}
