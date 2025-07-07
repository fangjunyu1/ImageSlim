//
//  ContentView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/18.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text(" \(Bundle.main.displayName)")
        }
        .frame(minWidth: 400,minHeight: 250)    // 限制最小尺寸
        .frame(maxWidth: 600,maxHeight: 350) // 限制最大尺寸
    }
}


#Preview {
    ContentView()
}
