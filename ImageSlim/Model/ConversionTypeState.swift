//
//  ConversionTypeState.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/8/25.
//

enum ConversionTypeState:String, CaseIterable, Hashable, Identifiable {
    var id: String { rawValue }
    
    /// JPEG 图像
    /// 常见扩展名: .jpg, .jpeg
    case jpg    // JPEG 图像
    case jpeg   // JPEG 图像
    
    /// PNG 图像
    /// 常见扩展名: .png
    case png    // PNG 图像
    
    /// TIFF 图像
    /// 常见扩展名: .tif, .tiff
    case tif    // TIFF 图像
    case tiff   // TIFF 图像
    
    /// GIF 动图
    /// 常见扩展名: .gif
    case gif    // GIF 动图
    
    /// BMP 位图
    /// 常见扩展名: .bmp
    case bmp    // BMP 位图
    
    // HEIF 图像容器
    /// 常见扩展名: .heif
    case heif   // HEIF 图像容器
    
    /// HEIC (HEIF + HEVC 编码)
    /// 常见扩展名: .heic
    case heic   // HEIC (HEIF + HEVC 编码)
    
    /// JPEG 2000
    /// 常见扩展名: .jp2, .j2k, .jpf, .jpx, .jpm
    case jp2
    case j2k
    case jpf
    case jpx
    case jpm
    
    /// Windows 图标文件
    /// 常见扩展名: .ico
    case ico
    
    /// PDF 文档
    /// 常见扩展名: .pdf
    case pdf
    
    /// SVG 矢量图
    /// 常见扩展名: .svg
    case svg
    
    /// WebP 图像
    /// 常见扩展名: .webp
    case webp   // WebP 图像
    
    /// RAW 图像（相机原始文件，包含多种厂商格式）
    /// 常见扩展名: .raw, .cr2, .nef, .arw, .dng, .orf, .rw2 等
    case raw    // RAW 图像（相机原始文件，包含多种厂商格式）
    case cr2    // RAW 图像（相机原始文件，包含多种厂商格式）
    case nef    // RAW 图像（相机原始文件，包含多种厂商格式）
    case arw    // RAW 图像（相机原始文件，包含多种厂商格式）
    case dng    // RAW 图像（相机原始文件，包含多种厂商格式）
    case orf    // RAW 图像（相机原始文件，包含多种厂商格式）
    case rw2    // RAW 图像（相机原始文件，包含多种厂商格式）
}
