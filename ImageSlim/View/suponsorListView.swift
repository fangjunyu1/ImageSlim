//
//  suponsorListView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/16.
//

import SwiftUI

struct suponsorListView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var iapManager = IAPManager.shared
    var item: SuponsorStruct
    @Binding var selectedNum:String?
    var body: some View {
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
                        .foregroundColor(selectedNum == item.id ? .white : colorScheme == .light ? .black : .white)
                    Text(item.subtitle)
                        .font(.footnote)
                        .foregroundColor(selectedNum == item.id ? Color(hex: "DADADA") : .gray)
                }
                Spacer()
                // 内购价格
                if let product = iapManager.products.first(where: { $0.id == item.id }) {
                    Text("\(product.displayPrice)")
                    .foregroundColor(selectedNum == item.id ? .white : colorScheme == .light ? .black : .white)
                } else {
                    Text("$ --)")
                        .foregroundColor(selectedNum == item.id ? .white : .black)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedNum == item.id ? Color.blue : colorScheme == .light ? Color.white : Color(hex: "2f2f2f"))
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
}

#Preview {
    suponsorListView(iapManager: IAPManager.shared, item: SuponsorStruct(id: "SponsoredCoffees", icon: "☕️", title: "Sponsor us a cup of coffee", subtitle: "Develop motivation to work overtime late at night", price: 1.0), selectedNum: .constant("SponsoredCoffee"))
        .environment(\.locale, .init(identifier: "ml")) // 设置为马拉雅拉姆语
}
