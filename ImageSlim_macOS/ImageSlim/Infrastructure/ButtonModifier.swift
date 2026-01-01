//
//  ButtonModifier.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/1.
//

import SwiftUI

extension Text {
    func BlueButtonText() -> some View {
        self
            .fontWeight(.bold)
            .padding(.vertical,6)
            .padding(.horizontal,24)
            .foregroundColor(.white)
            .background(Color(hex: "118DE6"))
            .cornerRadius(4)
    }
}
