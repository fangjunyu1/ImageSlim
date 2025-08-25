//
//  AdaptiveContentView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/8/25.
//

import SwiftUI

struct AdaptiveContentView<JudgmentView: View,ImageView: View,ImageList: View>: View {
    let isEmpty: Bool
    let title: JudgmentView
    let tips: JudgmentView
    let zstack: ImageView
    let list: ImageList
    
    init(isEmpty: Bool, @ViewBuilder title: () -> JudgmentView,@ViewBuilder tips: () -> JudgmentView, @ViewBuilder zstack: () -> ImageView, @ViewBuilder list: () -> ImageList) {
        self.isEmpty = isEmpty
        self.title = title()
        self.tips = tips()
        self.zstack = zstack()
        self.list = list()
    }
    
    var body: some View {
        if !isEmpty {
            HStack {
                Spacer()
                VStack {
                    title
                    Spacer().frame(height:20)
                    tips
                }
                Spacer().frame(width:30)
                zstack.scaleEffect(0.6).frame(width: 150)
                Spacer()
            }
            .frame(height: 140)
            list
        } else {
            VStack {
                title
                Spacer().frame(height:14)
                tips
                Spacer().frame(height:20)
                zstack
                Spacer().frame(height: 60)
            }
        }
        
    }
}
