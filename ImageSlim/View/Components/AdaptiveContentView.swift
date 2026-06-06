//
//  AdaptiveContentView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/8/25.
//

import SwiftUI

// 压缩/转换视图的自适应布局
// 没有图片时，显示默认的“转换图片”等文字、图片内容
// 如果有图片，则显示上方显示“转换图片”等文字、图片内容，底部显示图片列表

struct AdaptiveContentView<TitleView: View,JudgmentTextView: View,ImageView: View,ImageList: View>: View {
    let isEmpty: Bool
    let title: TitleView
    let tips: JudgmentTextView
    let zstack: ImageView
    let list: ImageList
    
    init(isEmpty: Bool, @ViewBuilder title: () -> TitleView,@ViewBuilder tips: () -> JudgmentTextView, @ViewBuilder zstack: () -> ImageView, @ViewBuilder list: () -> ImageList) {
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
