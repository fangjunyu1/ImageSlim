//
//  ContentView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/18.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var appStorage = AppStorage.shared
    var body: some View {
        VStack {
            Text("\(Bundle.main.appName)")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
                .frame(height: 14)
            Text("Open source image compression tool")
                .foregroundColor(.gray)
            
            Spacer().frame(height: 30)
            
            VStack(alignment: .leading) {
                // 压缩菜单-按钮
                Button(action: {
                    appStorage.selectedView = .compression
                }, label: {
                    Image(systemName: "photo")
                        .imageScale(.large)
                        .frame(width: 20)
                    Spacer().frame(width: 14)
                    Text("Compression")
                        .font(.title3)
                        .fontWeight(.semibold)
                })
                .buttonStyle(.plain)
                .foregroundColor(appStorage.selectedView == .compression ? .black : .gray)
                .onHover { isHovering in
                    isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                }
                
                Spacer().frame(height: 20)
                
                // 设置菜单-按钮
                Button(action: {
                    appStorage.selectedView = .settings
                }, label: {
                    Image(systemName: "slider.vertical.3")
                        .imageScale(.large)
                        .frame(width: 20)
                    Spacer().frame(width: 14)
                    Text("Settings")
                        .font(.title3)
                        .fontWeight(.semibold)
                })
                .buttonStyle(.plain)
                .foregroundColor(appStorage.selectedView == .settings ? .black : .gray)
                .onHover { isHovering in
                    isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                }
            }
            .frame(width: 100,alignment: .leading)
            
            Spacer()
            
            if appStorage.completeCompression {
                // 清除队列
                Button(action: {
                    print("清除队列")
                    appStorage.images = []
                }, label: {
                    ZStack {
                        Rectangle()
                            .frame(width: 120,height: 35)
                            .foregroundColor(Color(hex: "FF4343"))
                            .cornerRadius(10)
                        Text("Clear the queue")
                            .foregroundColor(.white)
                    }
                })
                .buttonStyle(.plain)
                .onHover { isHovering in
                    isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                }
                
                Spacer().frame(height: 20)
                
                // 下载全部
//                Button(action: {
//                    print("下载全部")
//                }, label: {
//                    ZStack {
//                        Rectangle()
//                            .frame(width: 120,height: 35)
//                            .foregroundColor(Color(hex: "3960EA"))
//                            .cornerRadius(10)
//                        Text("Download All")
//                            .foregroundColor(.white)
//                    }
//                })
//                .buttonStyle(.plain)
//                .onHover { isHovering in
//                    isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
//                }
//                
//                Spacer().frame(height: 20)
            }
            
            Text("\(Bundle.main.version)")
                .foregroundColor(.gray)
                .font(.footnote)
        }
        .frame(minWidth: 140,minHeight: 340)    // 限制最小尺寸
        .padding(30)
    }
}


#Preview {
    ContentView()
}
