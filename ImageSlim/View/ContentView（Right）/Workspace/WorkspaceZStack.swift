//
//  WorkspaceZStack.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/2.
//

import SwiftUI

struct WorkspaceZStack: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStorage: AppStorage
    var type: WorkTaskType
    var isHovering: Bool
    @Binding var showImporter: Bool
    var body: some View {
        switch type {
        case .compression:
            ZStack {
                Rectangle()
                    .frame(width: 240,height: 160)
                    .foregroundColor(
                        isHovering ? colorScheme == .light ? Color(hex: "BEE2FF") : Color(hex: "3d3d3d") :
                            colorScheme == .light ?  Color(hex:"E6E6E6") : Color(hex: "2f2f2f")
                    )
                    .cornerRadius(5)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 4)
                Image("upload")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
            }
            .modifier(HoverModifier())
            .onTapGesture {
                showImporter = true
            }
        case .conversion:
            ZStack {
                Rectangle()
                    .frame(width: 240,height: 160)
                    .foregroundColor(
                        isHovering ? colorScheme == .light ? Color(hex: "BEE2FF") : Color(hex: "3d3d3d"):
                            colorScheme == .light ?  Color(hex:"E6E6E6") : Color(hex: "2f2f2f")
                    )
                    .cornerRadius(5)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 4)
                Image("conversion")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
            }
            .modifier(HoverModifier())
            .onTapGesture {
                showImporter = true
            }
        }
    }
}

#Preview {
    WorkspaceZStack(type: .conversion, isHovering: true, showImporter: .constant(true))
        .environmentObject(AppStorage.shared)
}
