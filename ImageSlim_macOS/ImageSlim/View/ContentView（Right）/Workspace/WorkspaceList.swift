//
//  WorkspaceList.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/2.
//

import SwiftUI

struct WorkspaceList: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStorage: AppStorage
    @EnvironmentObject var workSpaceVM: WorkSpaceViewModel
    @EnvironmentObject var imageArray: ImageArrayViewModel
    var type: WorkTaskType
    var previewer: ImagePreviewWindow
    var body: some View {
        switch type {
        case .compression:
            ScrollView(showsIndicators:false) {
                ForEach(Array(imageArray.compressedImages.enumerated()),id: \.offset) { index,item in
                    ImageRowView(item: item,previewer: previewer,imageType: .compression)
                        .frame(maxWidth: .infinity)
                        .frame(height:42)
                    // 分割线
                    Divider()
                        .padding(.leading,55)
                        .opacity(imageArray.compressedImages.count - 1 == index ? 0 : 1)
                }
            }
            .modifier(WorkspaceListScrollViewModifier())
        case .conversion:
            ScrollView(showsIndicators:false) {
                ForEach(Array(imageArray.conversionImages.enumerated()),id: \.offset) { index,item in
                    ImageRowView(item: item,previewer: previewer,imageType: .conversion)
                        .frame(maxWidth: .infinity)
                        .frame(height:42)
                    // 分割线
                    Divider()
                        .padding(.leading,55)
                        .opacity(imageArray.conversionImages.count - 1 == index ? 0 : 1)
                }
            }
            .modifier(WorkspaceListScrollViewModifier())
        }
    }
}

struct WorkspaceListScrollViewModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity,maxHeight: .infinity)
            .padding(.vertical,20)
            .padding(.horizontal,30)
            .background(colorScheme == .light ? .white : Color(hex: "222222"))
            .cornerRadius(10)
    }
}

#Preview {
    WorkspaceList(type: .conversion, previewer: ImagePreviewWindow())
        .environmentObject(AppStorage.shared)
        .environmentObject(WorkSpaceViewModel.shared)
}
