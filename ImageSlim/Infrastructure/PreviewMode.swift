//
//  PreviewMode.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/11.
//

enum PreviewMode:String, CaseIterable, Hashable, Identifiable {
    var id: String { rawValue }
    
    case window
    case quickLook
}
