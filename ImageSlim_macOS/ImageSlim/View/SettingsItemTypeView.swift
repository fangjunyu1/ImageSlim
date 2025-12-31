//
//  SettingsItemTypeView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/12/31.
//

import SwiftUI

struct SettingsItemTypeView: View {
    @Environment(\.openURL) var openURL
    let type: SettingsItemType
    var body: some View {
        switch type {
        case .PickerIcon(let binding):
            Picker("显示图标", selection: binding) {
                Text("Always show").tag(true)
                Text("Off").tag(false)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize() // 不随容器拉伸
        case .CompressionSlider(let string, let binding):
            Text(string)
            Slider(value: binding,in: 0...1,step: 0.25)
                .frame(width: 100)
        case .PickerPreview(let binding):
            Picker("预览方式", selection: binding) {
                Text("Window preview").tag(PreviewMode.window)
                Text("Use Quick Look to preview").tag(PreviewMode.quickLook)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize() // 不随容器拉伸
        case .SaveLocationButton(let binding):
            Button(action: {
                FileUtils.createSaveLocation(saveName:binding)
            }, label: {
                Text(LocalizedStringKey(binding.wrappedValue))
            })
            .buttonStyle(.plain)
            .modifier(HoverModifier())
            .onAppear {
                FileUtils.refreshSaveName(saveName: binding)
            }
        case .ToggleThirdParty(let pngquant, let gifsicle):
            Text("Pngquant")
                .foregroundColor(.gray)
            Toggle("Pngquant",isOn: pngquant)
                .labelsHidden()
            
            Text("Gifsicle")
                .foregroundColor(.gray)
            Toggle("Gifsicle",isOn: gifsicle)
                .labelsHidden()
        case .Toggle(let string, let binding):
            Toggle(string,isOn: binding)
                .labelsHidden()
        case .Link(let string, let url):
            Text(LocalizedStringKey(string))
                .foregroundColor(.gray)
                .onTapGesture {
                    if let url = URL(string: url) {
                        openURL(url)
                    }
                }
                .modifier(HoverModifier())
        case .SendEmail(let string):
            Text(LocalizedStringKey(string))
                .foregroundColor(.gray)
                .onTapGesture {
                    FileUtils.sendEmail()
                }
                .modifier(HoverModifier())
        case .Thanks(let tuple):
            HStack(spacing:0) {
                ForEach(tuple.indices, id:\.self) { index in
                    Text(tuple[index].0)
                        .onTapGesture {
                            if let url = URL(string: tuple[index].1) {
                                openURL(url)
                            }
                        }
                        .modifier(HoverModifier())
                    if index != tuple.count - 1 {
                        Text(",")
                    }
                }
                .foregroundColor(.gray)
            }
        }
    }
}
