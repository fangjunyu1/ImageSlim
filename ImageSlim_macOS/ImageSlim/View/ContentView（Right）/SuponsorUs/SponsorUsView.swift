//
//  SponsorUsView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/14.
//

import SwiftUI

struct SponsorUsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var iapManager: IAPManager
    @EnvironmentObject var appStorage: AppStorage
    @State private var showRecovery = false
    
    private var suponsorList: [SuponsorStruct] = [
        SuponsorStruct(id: "SponsoredCoffee", icon: "☕️", title: "Buy us a coffee", subtitle: "Motivation for late-night development", price: 1.0),
        SuponsorStruct(id: "SponsorUsABurger", icon: "🍔", title: "Buy us a burger", subtitle: "Keep developers alive in Xcode.", price: 2.99),
        SuponsorStruct(id: "SponsorUsABook", icon: "📖", title: "Buy us a book", subtitle: "Helping us solve the next challenge", price: 6.0),
        SuponsorStruct(id: "SupportOurOpenSourceWork", icon: "🧑‍💻", title: "Support our open source mission", subtitle: "Because of you, we can keep bringing good tools to more people", price: 9.99)
    ]
    
    var body: some View {
            ScrollView(showsIndicators: false) {
                // 赞助我们-图片
                ZStack {
                    let topImgName = !appStorage.inAppPurchaseMembership ? "supportUs" : "thanks"
                    let topImgTitle = !appStorage.inAppPurchaseMembership ? "Sponsor Us" : "Thank you for your support!"
                    let topImgSubTitle = !appStorage.inAppPurchaseMembership ? "Give someone a rose, and the fragrance will linger on your hands" : "Your support keeps free software alive."
                    Image(topImgName)
                        .resizable()
                        .scaledToFill()
                        .cornerRadius(10)
                        .opacity(colorScheme == .light ? 1 : 0.3)
                    HStack {
                        if appStorage.inAppPurchaseMembership { Spacer()}
                        VStack {
                            Text(LocalizedStringKey(topImgTitle))
                                .font(.title2)
                            Spacer().frame(height:10)
                            Text(LocalizedStringKey(topImgSubTitle))
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }
                        .frame(width: 150)
                        if !appStorage.inAppPurchaseMembership { Spacer() }
                    }
                    .padding(.horizontal,10)
                }
                .frame(width:430,height:110)
                
                Spacer().frame(height:18)
                // 赞助列表
                VStack {
                    HStack{
                        Text("Sponsors")
                        Spacer()
                    }
                    ForEach(suponsorList) { item in
                        suponsorListView(item:item)
                    }
                    .padding(.vertical,2)
                    
                    Spacer().frame(height:10)
                    
                    Text("This sponsorship is a consumable in-app purchase. It unlocks the upload limit upon your first support. Please ensure iCloud is enabled for status syncing, as it does not support the standard system recovery.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                    
                    Spacer().frame(height:20)
                    
                    // 恢复内购代码
                    Button(action: {
                        let store = NSUbiquitousKeyValueStore.default
                        let iCloudIAP = store.bool(forKey: "inAppPurchaseMembership")
                        print("检查云端会员数据:\(iCloudIAP)")
                        appStorage.inAppPurchaseMembership = iCloudIAP
                        showRecovery = true
                    }, label: {
                        HStack(spacing:3) {
                            Text("Restore in-app purchases")
                                .fontWeight(.bold)
                            Text(verbatim: "(iCloud)")
                                .fontWeight(.bold)
                        }
                    })
                    .buttonStyle(.plain)
                    .modifier(HoverModifier())
                }
                Spacer().frame(height:20)
                
                // 关闭Sheet按钮
                VStack(spacing: 0){
                    Button(action:{
                        dismiss()
                    },label: {
                        Text("Off")
                            .BlueButtonText()
                    })
                    .buttonStyle(.plain)
                    .modifier(HoverModifier())
                }
                Spacer().frame(height:30)
                
#if DEBUG
                HStack(spacing:10) {
                    Button(action: {
                        appStorage.inAppPurchaseMembership = true
                        showRecovery = true
                    }, label: {
                        Text(verbatim: "新增内购标识")
                    })
                    Button(action: {
                        appStorage.inAppPurchaseMembership = false
                        showRecovery = true
                    }, label: {
                        Text(verbatim: "移除内购标识")
                    })
                }
                .font(.footnote)
                .buttonStyle(.plain)
                .foregroundColor(.gray)
                .padding(.vertical,10)
                
#endif
            }
        .frame(width: 400)
        .padding(.top,14)
        .padding(.horizontal,30)
        .overlay(LoadPurchased())   // 加载视图
        .sheet(isPresented: $iapManager.successTips) {
            SponsorUsResultsView()
        }
        .sheet(isPresented: $showRecovery) {
            SponsorUsRecoveryView()
        }
    }
}

#Preview {
    SponsorUsView()
        .environmentObject(IAPManager.shared)
        .environmentObject(AppStorage.shared)
//         .environment(\.locale, .init(identifier: "ml"))  // 设置为马拉雅拉姆语
}
