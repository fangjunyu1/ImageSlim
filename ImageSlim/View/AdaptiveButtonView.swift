//
//  AdaptiveButtonView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/8/25.
//

import SwiftUI

struct AdaptiveButtonView: View {
    @ObservedObject var appStorage = AppStorage.shared
    var isEmpty: Bool
    @Binding var images: [CustomImages]
    @Binding var showDownloadsProgress: Bool
    @Binding var progress: Double
    var zipImages: () -> Void
    
    var body: some View {
        
        if (!appStorage.inAppPurchaseMembership && images.contains { $0.inputSize < 5_000_000 }) ||
            (appStorage.inAppPurchaseMembership && !images.isEmpty) {
            
            // 清除队列
            Button(action: {
                print("清除队列")
                images = []
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
            Button(action: {
                Task {
                    zipImages()
                }
            }, label: {
                ZStack {
                    if showDownloadsProgress {
                        Rectangle()
                            .frame(width: 120,height: 35)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width:100,height:35)
                        
                    } else {
                        Rectangle()
                            .frame(width: 120,height: 35)
                            .foregroundColor(Color(hex: "3960EA"))
                            .cornerRadius(10)
                        Text("Download All")
                            .foregroundColor(.white)
                    }
                }
            })
            .buttonStyle(.plain)
            .onHover { isHovering in
                isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
            }
        } else {
            Color.clear.frame(width: 120,height:35)
                .opacity(0)
        }
        
        Spacer().frame(height: 20)
    }
}
