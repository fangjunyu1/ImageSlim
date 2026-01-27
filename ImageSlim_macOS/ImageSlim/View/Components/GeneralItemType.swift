//
//  GeneralItemType.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/12/31.
//

import SwiftUI

enum GeneralItemType {
    case PickerIcon(Binding<Bool>)
    case CompressionSlider(Binding<Double>)
    case PickerPreview(Binding<PreviewMode>)
    case SaveLocationButton
    case ToggleThirdParty(pngquant: Binding<Bool>,gifsicle: Binding<Bool>,cwebp: Binding<Bool>)
    case Toggle(String,Binding<Bool>)
    case Link(String, url: String)
    case SendEmail(String)
    case Thanks([(String, String)])
    case TempStorageUsed
    case Int(Int)
    case Int64(Int64)
    case IntSize(Int64)
    case Double(Double)
    case Date(Date?)
}
