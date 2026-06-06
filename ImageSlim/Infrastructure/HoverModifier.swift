//
//  HoverModifier.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/12/31.
//

import SwiftUI

struct HoverModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onHover { isHovering in
                isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
            }
    }
}
