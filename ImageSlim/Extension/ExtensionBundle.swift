//
//  ExtensionBundle.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/7.
//

import Foundation

extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "App"
    }

    var version: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var build: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}
