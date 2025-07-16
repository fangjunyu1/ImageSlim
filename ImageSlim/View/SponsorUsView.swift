//
//  SponsorUsView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/14.
//

import SwiftUI

struct SuponsorStruct: Identifiable{
    var id:String
    var icon: String
    var title: LocalizedStringKey
    var subtitle: LocalizedStringKey
    var price: Double
}

struct SponsorUsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedNum: String? = nil
    @ObservedObject var appStorage = AppStorage.shared
    @ObservedObject var iapManager = IAPManager.shared
    private var suponsorList: [SuponsorStruct] = [
        SuponsorStruct(id: "SponsoredCoffee", icon: "☕️", title: "Sponsor us a cup of coffee", subtitle: "Develop motivation to work overtime late at night", price: 1.0),
        SuponsorStruct(id: "SponsorUsABurger", icon: "🍔", title: "Sponsor us a burger", subtitle: "Don't let developers starve to death in Xcode", price: 2.99),
        SuponsorStruct(id: "SponsorUsABook", icon: "📖", title: "Sponsor us a book", subtitle: "We may be able to solve the next problem with it", price: 6.0),
        SuponsorStruct(id: "SupportOurOpenSourceWork", icon: "🧑‍💻", title: "Support our open source business", subtitle: "Because of you, we can insist on bringing good tools to more people", price: 9.99)
    ]
    var body: some View {
        VStack {
            // 赞助视图
            ScrollView(showsIndicators: false) {
                // 赞助我们-图片
                ZStack {
                    if !appStorage.inAppPurchaseMembership {
                        Image("supportUs")
                            .resizable()
                            .scaledToFill()
                            .cornerRadius(10)
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
                
                Spacer().frame(height:10)
                // 赞助列表
                VStack {
                    HStack{
                        Text("Sponsorship List")
                        Spacer()
                    }
                    ForEach(suponsorList) { item in
                        
                        Button(action: {
                            if let product = iapManager.products.first(where: { $0.id == item.id }) {
                                if !iapManager.products.isEmpty {
                                    iapManager.loadPurchased = true // 显示加载动画
                                    // 分开调用购买操作
                                    iapManager.purchaseProduct(product)
                                } else {
                                    print("未找到对应产品")
                                    Task {
                                        await iapManager.loadProduct()   // 加载产品信息
                                    }
                                }
                            }
                        },label: {
                            HStack {
                                Text("\(item.icon)")
                                    .font(.largeTitle)
                                Spacer().frame(width:10)
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.callout)
                                        .foregroundColor(selectedNum == item.id ? .white : .black)
                                    Text(item.subtitle)
                                        .font(.footnote)
                                        .foregroundColor(selectedNum == item.id ? Color(hex: "DADADA") : .gray)
                                }
                                Spacer()
                                if let product = iapManager.products.first(where: { $0.id == item.id }) {
                                    Text("\(product.displayPrice)")
                                        .foregroundColor(selectedNum == item.id ? .white : .black)
                                } else {
                                    Text("$ --)")
                                        .foregroundColor(selectedNum == item.id ? .white : .black)
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedNum == item.id ? Color.blue : Color.white)
                                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 3)
                            )
                        })
                        .buttonStyle(.plain)
                        .onHover { isHovering in
                            if isHovering {
                                selectedNum = item.id
                                NSCursor.pointingHand.set()
                            } else {
                                selectedNum = nil
                                NSCursor.arrow.set()
                            }
                        }
                    }
                    .padding(.vertical,2)
                    
                    Spacer().frame(height:10)
                    
                    Text("This sponsorship project is a one-time consumable in-app purchase. It only unlocks the upload limit when you purchase it for the first time. The service will not be repeated in the future, and it does not support recovery.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                    
                    Spacer().frame(height:10)
                    Button(action: {
                        
                    }, label: {
                        Text("Restore in-app purchases")
                            .fontWeight(.bold)
                    })
                    .onHover { isHovering in
                        isHovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                    }
                }
            }
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
        }
        .padding(14)
        .frame(minWidth: 450, minHeight: 530)
    }
}

#Preview {
    SponsorUsView()
}
