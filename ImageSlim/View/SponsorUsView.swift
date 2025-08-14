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
    @State private var selectedNum: String? = nil
    @ObservedObject var iapManager = IAPManager.shared
    @ObservedObject var appStorage = AppStorage.shared
    private var suponsorList: [SuponsorStruct] = [
        SuponsorStruct(id: "SponsoredCoffee", icon: "☕️", title: "Sponsor us a cup of coffee", subtitle: "Develop motivation to work overtime late at night", price: 1.0),
        SuponsorStruct(id: "SponsorUsABurger", icon: "🍔", title: "Sponsor us a burger", subtitle: "Don't let developers starve to death in Xcode", price: 2.99),
        SuponsorStruct(id: "SponsorUsABook", icon: "📖", title: "Sponsor us a book", subtitle: "We may be able to solve the next problem with it", price: 6.0),
        SuponsorStruct(id: "SupportOurOpenSourceWork", icon: "🧑‍💻", title: "Support our open source business", subtitle: "Because of you, we can insist on bringing good tools to more people", price: 9.99)
    ]
    var body: some View {
            ScrollView(showsIndicators: false) {
                // 赞助我们-图片
                ZStack {
                    if !appStorage.inAppPurchaseMembership {
                        Image("supportUs")
                            .resizable()
                            .scaledToFill()
                            .cornerRadius(10)
                            .opacity(colorScheme == .light ? 1 : 0.3)
                        HStack {
                            VStack {
                                Text("Sponsor Us")
                                    .font(.title2)
                                Spacer().frame(height:10)
                                Text("Give someone a rose, and the fragrance will linger on your hands")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                            }
                            .frame(width: 150)
                            Spacer()
                        }
                        .padding(.leading,10)
                    } else {
                        Image("thanks")
                            .resizable()
                            .scaledToFill()
                            .cornerRadius(10)
                            .opacity(colorScheme == .light ? 1 : 0.3)
                        HStack {
                            Spacer()
                            VStack {
                                Text("Thank you for your support")
                                    .font(.title2)
                                Spacer().frame(height:10)
                                Text("Your support keeps free software alive.")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                            }
                            .frame(width: 170)
                        }
                        .padding(.trailing,10)
                    }
                }
                .frame(width:430,height:110)
                
                Spacer().frame(height:18)
                // 赞助列表
                VStack {
                    HStack{
                        Text("Sponsorship List")
                        Spacer()
                    }
                    ForEach(suponsorList) { item in
                        suponsorListView(item:item,selectedNum: $selectedNum)
                    }
                    .padding(.vertical,2)
                    
                    Spacer().frame(height:10)
                    
                    Text("This sponsorship project is a one-time consumable in-app purchase. It only unlocks the upload limit when you purchase it for the first time. The service will not be repeated in the future, and it does not support recovery.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                    
                    Spacer().frame(height:20)
                    
                    // 恢复内购代码
                    Button(action: {
                        let store = NSUbiquitousKeyValueStore.default
                        appStorage.inAppPurchaseMembership = store.bool(forKey: "enableThirdPartyLibraries")
                    }, label: {
                        HStack(spacing:0) {
                            Text("Restore in-app purchases")
                                .fontWeight(.bold)
                            Text("(iCloud)")
                                .fontWeight(.bold)
                        }
                    })
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                    }
                }
                Spacer().frame(height:20)
                
                // 关闭Sheet按钮
                VStack(spacing: 0){
                    Button(action:{
                        print("点击了关闭按钮")
                        dismiss()
                    },label: {
                        Text("Off")
                            .fontWeight(.bold)
                            .padding(.vertical,6)
                            .padding(.horizontal,24)
                            .foregroundColor(.white)
                            .background(Color(hex: "118DE6"))
                            .cornerRadius(4)
                    })
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                    }
                }
                Spacer().frame(height:30)
            }
        .frame(width: 400)
        .padding(.top,14)
        .padding(.horizontal,30)
        .overlay {
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
        .overlay {
            if iapManager.successTips {
                ZStack {
                    Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color(hex: "416DFF"))
                            .font(.system(size: 48))
                        Text("Thank you for your support")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Button(action: {
                            iapManager.successTips = false
                        }, label: {
                            Text("Sponsorship success")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.vertical,8)
                                .padding(.horizontal,20)
                                .background(Color(hex: "118DE6"))
                                .cornerRadius(3)
                        })
                        .buttonStyle(.plain)
                        .onHover { isHovering in
                            isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                        }
                    }
                    .frame(width: 200,height:170)
                    .background(.white)
                    .cornerRadius(10)
                    .cornerRadius(10)
                }
            }
        }
    }
}

#Preview {
    SponsorUsView()
        // .environment(\.locale, .init(identifier: "ml")) // 设置为马拉雅拉姆语
}
