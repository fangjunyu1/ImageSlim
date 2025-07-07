//
//  ContentView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/18.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HStack {
            VStack {
                VStack(alignment: .leading) {
                    Text("\(Bundle.main.appName)")
                        .font(.title)
                    Spacer()
                        .frame(height: 20)
                    Text("Open source image compression tool")
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("\(Bundle.main.version)")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
            Spacer()
        }
        .frame(minWidth: 600,minHeight: 250)    // 限制最小尺寸
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .padding(30)
    }
}


#Preview {
    ContentView()
}
