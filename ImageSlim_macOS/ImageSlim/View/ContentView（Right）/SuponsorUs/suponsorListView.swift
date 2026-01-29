//
//  suponsorListView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/16.
//

import SwiftUI

struct suponsorListView: View {
    @Environment(\.colorScheme) var colorScheme
    var iapManager = IAPManager.shared
    var item: SuponsorStruct
    @State var onHover: Bool = false
    
    var body: some View {
        Button(action: {
            if let product = iapManager.products.first(where: { $0.id == item.id }) {
                    iapManager.loadPurchased = true // 显示加载动画
                    // 分开调用购买操作
                    iapManager.purchaseProduct(product)
            } else {
                print("未找到对应产品")
                Task {
                    await iapManager.loadProduct()   // 加载产品信息
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
                        .foregroundColor(onHover ? .white : colorScheme == .light ? .black : .white)
                    Text(item.subtitle)
                        .font(.footnote)
                        .foregroundColor(onHover ? Color(hex: "DADADA") : .gray)
                }
                Spacer()
                // 内购价格
                if let product = iapManager.products.first(where: { $0.id == item.id }) {
                    Text("\(product.displayPrice)")
                    .foregroundColor(onHover ? .white : colorScheme == .light ? .black : .white)
                } else {
                    Text("$ --")
                        .foregroundColor(onHover ? .white : .black)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(onHover ? Color.blue : colorScheme == .light ? Color.white : Color(hex: "2f2f2f"))
                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 3)
            )
        })
        .buttonStyle(.plain)
        .onHover { isHovering in
            onHover = isHovering
        }
        .modifier(HoverModifier())
    }
}

#Preview {
    VStack {
        suponsorListView(iapManager: IAPManager.shared, item: SuponsorStruct(id: "SponsoredCoffees", icon: "☕️", title: "Buy us a coffee", subtitle: "Motivation for late-night development", price: 1.0))
            // .environment(\.locale, .init(identifier: "ml")) // 设置为马拉雅拉姆语
    }
    .frame(width: 300)
}
