//
//  StatisticsManager.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/27.
//

import SwiftUI

struct StatisticsModel {
    // 已压缩图片数量
    var imagesCompressed: Int64
    // 已转换图片数量
    var imagesConverted: Int64
    // 原始图片总大小
    var originalSize: Int64
    // 压缩后总大小
    var compressedSize: Int64
}

struct StatisticsManager {
    
    
    // 更新统计数据
    @MainActor static func StatisticsMethods(_ stat: StatisticsModel) {
        
        let appStorage = AppStorage.shared
        
        // 1、累加基础数据
        appStorage.imagesCompressed += stat.imagesCompressed
        appStorage.imagesConverted += stat.imagesConverted
        appStorage.originalSize += stat.originalSize
        appStorage.compressedSize += stat.compressedSize
        
        // 2、单张最大节省空间
        let currentSaved = stat.originalSize - stat.compressedSize
        if currentSaved > 0 {
            appStorage.maxSizeSaved = max(appStorage.maxSizeSaved, currentSaved)
        }
        
        // 3、最大压缩率
        if stat.originalSize > 0 {
            let currentRatio = Double(stat.compressedSize) / Double(stat.originalSize)
            if appStorage.maxCompressionRatio < currentRatio {
                appStorage.maxCompressionRatio = currentRatio
            }
            
        }
        
        
        // 最近一次处理时间
        appStorage.lastProcessed = Date()
    }
    
    @MainActor static func StatisticsDate() {
        
        let appStorage = AppStorage.shared
        
        // 首次使用时间
        if appStorage.firstUsed == Date.distantPast {
            appStorage.firstUsed = Date()
        }

        // 累计使用天数
        if appStorage.lastDaysUsed != Date.distantPast {
            // 如果当前时间和最近一次处理时间不是同一天，则累计使用天数 +1
            let isSameDay = Calendar.current.isDate(Date(), inSameDayAs: appStorage.lastDaysUsed)
            if !isSameDay {
                appStorage.daysUsed += 1
            }
        } else {
            appStorage.daysUsed = 1
        }
        
        appStorage.lastDaysUsed = Date()
    }
    
    @MainActor static func ResetStatistics() {
        let appStorage = AppStorage.shared
        print("重置统计数据")
        appStorage.imagesCompressed = 0
        appStorage.imagesConverted = 0
        appStorage.originalSize = 0
        appStorage.compressedSize = 0
        appStorage.maxSizeSaved = 0
        appStorage.maxCompressionRatio = 0
        appStorage.lastProcessed = Date.distantPast
        appStorage.firstUsed = Date()
        appStorage.lastDaysUsed = Date()
        appStorage.daysUsed = 1
    }
}
