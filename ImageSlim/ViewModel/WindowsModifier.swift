//
//  WindowsModifier.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//

import SwiftUICore

struct WindowsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(minWidth: 400, minHeight: 400)
            .frame(maxWidth: 650,maxHeight: 550)
    }
}
