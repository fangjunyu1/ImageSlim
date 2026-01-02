//
//  SettingsItemType.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/12/31.
//

import SwiftUI

enum SettingsItemType {
    case PickerIcon(Binding<Bool>)
    case CompressionSlider(LocalizedStringKey, Binding<Double>)
    case PickerPreview(Binding<PreviewMode>)
    case SaveLocationButton
    case ToggleThirdParty(pngquant: Binding<Bool>,gifsicle: Binding<Bool>)
    case Toggle(String,Binding<Bool>)
    case Link(String,String)
    case SendEmail(String)
    case Thanks([(String, String)])
}
