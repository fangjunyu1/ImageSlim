//
//  ContentView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/18.
//

import SwiftUI
import Zip

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStorage = AppStorage.shared
    @State private var progress = 0.0
    @State private var showDownloadsProgress = false
    @State private var showSponsorUs = false
    
    func zipImages() {
        showDownloadsProgress = true
        progress = 0.0
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("zipImages 任务中是否是主线程？", Thread.isMainThread)
                print("打包Zip")
                var directory:FileManager.SearchPathDirectory {
                    switch appStorage.imageSaveDirectory {
                    case .downloadsDirectory:
                        return .downloadsDirectory
//                    case .picturesDirectory:
//                        return .picturesDirectory
                    }
                }
                
                let directoryURL = FileManager.default.urls(for: directory, in: .userDomainMask)[0]
                let destinationURL = directoryURL.appendingPathComponent("ImageSlim.zip")
                var ImagesURL:[URL] {
                    let urls = appStorage.images.compactMap { $0.outputURL }
                    return urls
                }
                try Zip.zipFiles(paths: ImagesURL, zipFilePath: destinationURL, password: nil) { progress in
                    DispatchQueue.main.async {
                        self.progress = progress
                        if progress == 1 {
                            showDownloadsProgress = false
                        }
                    }
                }
                DispatchQueue.main.async {
                    print("打包完成")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showDownloadsProgress = false
                    print("打包失败")
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("\(Bundle.main.appName)")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
                .frame(height: 14)
            Text("Open source image compression tool")
                .foregroundColor(.gray)
            
            Spacer().frame(height: 20)
            
            VStack(alignment: .leading) {
                // 压缩菜单-按钮
                Button(action: {
                    appStorage.selectedView = .compression
                }, label: {
                    HStack {
                        Image(systemName: "photo")
                            .imageScale(.large)
                            .frame(width: 20)
                        Spacer().frame(width: 14)
                        Text("Compression")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .contentShape(Rectangle())
                })
                .buttonStyle(.plain)
                .foregroundColor(appStorage.selectedView == .compression ?
                                 colorScheme == .light ? .black : .white :
                        .gray)
                .onHover { isHovering in
                    isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                }
                
                Spacer().frame(height: 20)
                
                // 设置菜单-按钮
                Button(action: {
                    appStorage.selectedView = .settings
                }, label: {
                    HStack {
                        Image(systemName: "slider.vertical.3")
                            .imageScale(.large)
                            .frame(width: 20)
                        Spacer().frame(width: 14)
                        Text("Settings")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .contentShape(Rectangle())
                })
                .buttonStyle(.plain)
                .foregroundColor(appStorage.selectedView == .settings ?
                                 colorScheme == .light ? .black : .white :
                        .gray)
                .onHover { isHovering in
                    isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                }
            }
            .frame(width: 130)
            .lineLimit(1)
            .minimumScaleFactor(0.5) // 最多缩小到原始字体大小的 50%
            
            Spacer()
            
            if !appStorage.images.isEmpty {
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
                Button(action: {
                    Task {
                        zipImages()
                    }
                }, label: {
                    ZStack {
                        if showDownloadsProgress {
                            ProgressView(value: progress, total: 1.0)
                                            .progressViewStyle(LinearProgressViewStyle())
                                            .padding()
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
                
                Spacer().frame(height: 20)
                
            }
            
            Button(action:{
                showSponsorUs = true
            }, label: {
                if appStorage.inAppPurchaseMembership {
                    Text("Thank you for your support")
                        .font(.footnote)
                        .foregroundColor(appStorage.selectedView == .sponsorUs ? .black : .gray)
                        .onHover { isHovering in
                            isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                        }
                } else {
                    Text("Sponsor Us")
                        .font(.footnote)
                        .foregroundColor(appStorage.selectedView == .sponsorUs ? .black : .gray)
                        .onHover { isHovering in
                            isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                        }
                }
            })
            .buttonStyle(.plain)
            .multilineTextAlignment(.center)
                
            Spacer().frame(height:10)
            Text("\(Bundle.main.version) (\(Bundle.main.build))")
                .foregroundColor(.gray)
                .font(.footnote)
        }
        .frame(minWidth: 140,minHeight: 340)    // 限制最小尺寸
        .padding(30)
        .sheet(isPresented: $showSponsorUs) {
            SponsorUsView()
        }
    }
}


#Preview {
    ContentView()
        .frame(width:200)
        .environment(\.locale, .init(identifier: "ml")) // 设置为德语
}
