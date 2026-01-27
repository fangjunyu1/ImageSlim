//
//  Statistics.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/24.
//

import SwiftUI

struct Statistics: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appStorage: AppStorage
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                
                // 核心统计
                Section(header:
                            Text("Core Stats")
                    .font(.headline)
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        // 已压缩图片数量
                        GeneralItemView(
                            icon: "photo",
                            title: "Images Compressed",
                            type: .Int64(appStorage.imagesCompressed))
                        Divider().padding(.leading,25)
                        
                        // 已转换图片数量
                        GeneralItemView(
                            icon: "photo.on.rectangle.angled",
                            title: "Images Converted",
                            type: .Int64(appStorage.imagesConverted))
                        Divider().padding(.leading,25)
                        
                        // 已处理图片总数数量
                        GeneralItemView(
                            icon: "photo.on.rectangle",
                            title: "Total Images Processed",
                            type: .Int64(appStorage.totalImagesProcessed))
                        Divider().padding(.leading,25)
                        
                        // 原始图片总大小
                        GeneralItemView(
                            icon: "tray.full",
                            title: "Original Size",
                            type: .IntSize(appStorage.originalSize))
                        Divider().padding(.leading,25)
                        
                        // 压缩后总大小
                        GeneralItemView(
                            icon: "tray",
                            title: "Compressed Size",
                            type: .IntSize(appStorage.compressedSize))
                        Divider().padding(.leading,25)
                        
                        // 节省硬盘空间
                        GeneralItemView(
                            icon: "externaldrive",
                            title: "Disk Space Saved",
                            type: .IntSize(appStorage.diskSpaceSaved))
                    }
                    .modifier(GeneralVSModifier())
                }
                
                Spacer().frame(height:20)
                
                // 压缩效果
                Section(header:
                            Text("Compression Stats")
                    .font(.headline)
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        // 平均压缩率
                        GeneralItemView(
                            icon: "line.3.horizontal.decrease",
                            title: "Avg. Compression Ratio",
                            type: .Double(appStorage.avgCompressionRatio))
                        Divider().padding(.leading,25)
                        
                        // 平均压缩后大小
                        GeneralItemView(
                            icon: "flowchart",
                            title: "Avg. Compressed Size",
                            type: .IntSize(Int64(appStorage.avgCompressedSize)))
                        Divider().padding(.leading,25)
                        
                        // 最大单张节省空间
                        GeneralItemView(
                            icon: "slider.horizontal.below.rectangle",
                            title: "Max Size Saved",
                            type: .IntSize(appStorage.maxSizeSaved))
                        Divider().padding(.leading,25)
                        
                        // 最大压缩率
                        GeneralItemView(
                            icon: "square.grid.4x3.fill",
                            title: "Max Compression Ratio",
                            type: .Double(appStorage.maxCompressionRatio))
                    }
                    .modifier(GeneralVSModifier())
                }
                
                Spacer().frame(height:20)
                
                // 使用记录
                Section(header:
                            Text("Usage Info")
                    .font(.headline)
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        
                        // 最近一次处理时间
                        GeneralItemView(
                            icon: "clock",
                            title: "Last Processed",
                            type: .Date(appStorage.lastProcessed))
                        Divider().padding(.leading,25)
                        
                        // 首次使用时间
                        GeneralItemView(
                            icon: "calendar",
                            title: "First Used",
                            type: .Date(appStorage.firstUsed))
                        Divider().padding(.leading,25)
                        
                        // 累计使用天数
                        GeneralItemView(
                            icon: "chart.pie",
                            title: "Days Used",
                            type: .Int(appStorage.daysUsed))
                        
                    }
                    .modifier(GeneralVSModifier())
                }
            }
            Spacer().frame(height:20)
            
            Button(action:{
                // 重置统计数据
                StatisticsManager.ResetStatistics()
            }, label:  {
                Text("Reset Statistics")
                    .foregroundColor(.gray)
            })
            .buttonStyle(.plain)
            .modifier(HoverModifier())
        }
        .modifier(WindowsModifier())
    }
}

#Preview {
    Statistics()
        .environmentObject(AppStorage.shared)
}
