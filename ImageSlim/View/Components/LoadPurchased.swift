//
//  LoadPurchased.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/1.
//

import SwiftUI

struct LoadPurchased: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var iapManager: IAPManager
    var body: some View {
        if iapManager.loadPurchased {
            ZStack {
                Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                VStack {
                    // 加载条
                    ProgressView("loading...")
                    // 加载条修饰符
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(colorScheme == .dark ? Color(hex: "A8AFB3") : Color.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}
