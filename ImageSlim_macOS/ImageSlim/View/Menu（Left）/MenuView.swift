//
//  MenuView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/18.
//

import SwiftUI
import Zip

struct MenuView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStorage: AppStorage
    @State private var showSponsorUs = false
    
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
                    .fixedSize()
                })
                .buttonStyle(.plain)
                .foregroundColor(appStorage.selectedView == .compression ?
                                 colorScheme == .light ? .black : .white :
                        .gray)
                .modifier(HoverModifier())
                
                if appStorage.EnableImageConversion {
                    Spacer().frame(height: 20)
                    
                    // 转换菜单-按钮
                    Button(action: {
                        appStorage.selectedView = .conversion
                    }, label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .imageScale(.large)
                                .frame(width: 20)
                            Spacer().frame(width: 14)
                            Text("Conversion")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .contentShape(Rectangle())
                        .fixedSize()
                    })
                    .buttonStyle(.plain)
                    .foregroundColor(appStorage.selectedView == .conversion ?
                                     colorScheme == .light ? .black : .white :
                            .gray)
                    .modifier(HoverModifier())
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
                    .fixedSize()
                })
                .buttonStyle(.plain)
                .foregroundColor(appStorage.selectedView == .settings ?
                                 colorScheme == .light ? .black : .white :
                        .gray)
                .modifier(HoverModifier())
            }
            .frame(width: 130)
            .lineLimit(1)
            .minimumScaleFactor(0.5) // 最多缩小到原始字体大小的 50%
            
            Spacer()
            
            // 清除队列和下载全部视图
            AdaptiveButtonView()
            
            Button(action:{
                showSponsorUs = true
            }, label: {
                if appStorage.inAppPurchaseMembership {
                    Text("Thank you for your support")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .modifier(HoverModifier())
                } else {
                    Text("Sponsor Us")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .modifier(HoverModifier())
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
    MenuView()
        .frame(width:200)
        .environmentObject(AppStorage.shared)
        .environmentObject(ImageArrayViewModel.shared)
    // .environment(\.locale, .init(identifier: "ml")) // 设置为德语
}
