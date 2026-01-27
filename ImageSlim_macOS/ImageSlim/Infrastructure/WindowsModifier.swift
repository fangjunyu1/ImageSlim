//
//  WindowsModifier.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//

import SwiftUI

struct WindowsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(minWidth: 400, minHeight: 450)
            .frame(maxWidth: 900,maxHeight: 750)
    }
}
