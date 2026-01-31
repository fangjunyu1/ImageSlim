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
            Text("Open source image compressor")
                .font(.subheadline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer().frame(height: 20)
            
            VStack(alignment: .leading) {
                // 压缩菜单-按钮
                Button(action: {
                    appStorage.selectedView = .compression
                }, label: {
                    MenuViewButton(image: "photo", text: "Compress")
                })
                .buttonStyle(.plain)
                .foregroundColor(appStorage.selectedView == .compression ?
                                 colorScheme == .light ? .black : .white :
                        .gray)
                .modifier(HoverModifier())
                
                // 转换功能
                if appStorage.EnableImageConversion {
                    Spacer().frame(height: 20)
                    
                    // 转换菜单-按钮
                    Button(action: {
                        appStorage.selectedView = .conversion
                    }, label: {
                        MenuViewButton(image: "photo.on.rectangle.angled", text: "Convert")
                    })
                    .buttonStyle(.plain)
                    .foregroundColor(appStorage.selectedView == .conversion ?
                                     colorScheme == .light ? .black : .white :
                            .gray)
                    .modifier(HoverModifier())
                }
                
                // 统计功能
                if appStorage.enableStatistics {
                    Spacer().frame(height: 20)
                    
                    // 统计菜单-按钮
                    Button(action: {
                        appStorage.selectedView = .statistics
                    }, label: {
                        MenuViewButton(image: "chart.bar", text: "Statistics")
                    })
                    .buttonStyle(.plain)
                    .foregroundColor(appStorage.selectedView == .statistics ?
                                     colorScheme == .light ? .black : .white :
                            .gray)
                    .modifier(HoverModifier())
                }
                Spacer().frame(height: 20)
                
                // 设置菜单-按钮
                Button(action: {
                    appStorage.selectedView = .settings
                }, label: {
                    MenuViewButton(image: "slider.vertical.3", text: "Settings")
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
                    Text("Thank you for your support!")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8) // 最多缩小到原始字体大小的 50%
                } else {
                    Text("Sponsor Us")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8) // 最多缩小到原始字体大小的 50%
                }
            })
            .buttonStyle(.plain)
            .multilineTextAlignment(.center)
            .modifier(HoverModifier())
            
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

private struct MenuViewButton: View {
    let image: String
    let text: String
    var body: some View {
        HStack {
            Image(systemName: image)
                .imageScale(.large)
                .frame(width: 20)
            Spacer().frame(width: 14)
            Text(LocalizedStringKey(text))
                .font(.title3)
                .fontWeight(.semibold)
        }
        .lineLimit(2)
        .minimumScaleFactor(0.8)
        .contentShape(Rectangle())
        .fixedSize()
    }
}

#Preview {
    MenuView()
        .frame(width:200)
        .environmentObject(AppStorage.shared)
        .environmentObject(ImageArrayViewModel.shared)
        .environment(\.locale, .init(identifier: "ml")) // 设置为德语
}
