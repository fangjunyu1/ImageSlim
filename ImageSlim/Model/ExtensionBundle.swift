//
//  ExtensionBundle.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import Foundation

extension Bundle {
    var displayName: String {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "App"
    }
}
