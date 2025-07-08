//
//  WorkspaceView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import SwiftUI

struct WorkspaceView: View {
    @ObservedObject var data = TemporaryData.shared
    var body: some View {
        if data.selectedView == .compression {
            CompressionView()
        } else if data.selectedView == .settings {
            SettingsView()
        } else {
            
        }
    }
}

#Preview {
    WorkspaceView()
}
