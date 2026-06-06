//
//  ExtensionDouble.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/27.
//

import SwiftUI

extension Double {
    func percentageFormattedWithTwoDecimalPlaces() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "0.00"
    }
}
