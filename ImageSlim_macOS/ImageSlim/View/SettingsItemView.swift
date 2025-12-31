//
//  SettingsItemView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/12/31.
//

import SwiftUI

struct SettingsItemView: View {
    let icon: String
    let title: String
    let type: SettingsItemType
    
    init(icon: String, title: String, type: SettingsItemType) {
        self.icon = icon
        self.title = title
        self.type = type
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(LocalizedStringKey(title))
            Spacer()
            SettingsItemTypeView(type: type)
        }
    }
}
