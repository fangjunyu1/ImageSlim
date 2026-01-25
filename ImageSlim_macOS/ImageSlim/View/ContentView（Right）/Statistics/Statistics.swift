//
//  Statistics.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/24.
//

import SwiftUI

struct Statistics: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStorage: AppStorage
    
    var body: some View {
        VStack {
            
        }
        .modifier(WindowsModifier())
    }
}

#Preview {
    Statistics()
        .environmentObject(AppStorage.shared)
}
