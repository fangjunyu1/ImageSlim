//
//  LottieView.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/1.
//

import SwiftUI
import Lottie
import AppKit

struct LottieMacView: NSViewRepresentable {
    var filename: String
    var isPlaying: Bool
    var playCount: Int
    var isReversed: Bool
    var tintColor: NSColor? = nil
    
    // 添加 contentMode 参数，默认为 .scaleAspectFit
    var contentMode: LottieContentMode = .scaleAspectFit
    
    class Coordinator {
        var parent: LottieMacView
        init(parent: LottieMacView) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        
        // 创建 Lottie 动画视图
        let animationView = LottieAnimationView(name: filename)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.loopMode = playCount == 0 ? .loop : .playOnce
        
        // --- 关键修改 1: 使用 Lottie 自带的 contentMode ---
        // 不要使用 layer.contentsGravity，Lottie 提供了跨平台的 contentMode 属性
        animationView.contentMode = contentMode
        
        // --- 关键修改 2: 允许视图被压缩 ---
        // 这告诉 Auto Layout：如果外部（SwiftUI frame）要求更小的尺寸，请缩小，不要坚持原始大小
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        view.addSubview(animationView)
        
        // 约束设置正确：让 animationView 撑满父视图
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if isPlaying {
            playAnimation(animationView, playCount: playCount, isReversed: isReversed)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let animationView = nsView.subviews.first as? LottieAnimationView else { return }
        
        // 更新 contentMode (如果需要动态支持)
        animationView.contentMode = contentMode
        
        if isPlaying {
            // 如果已经在播放且状态未变，通常不需要重新调用 play，
            // 但这里为了简化逻辑保留原样。生产环境建议判断 isAnimationPlaying
            if !animationView.isAnimationPlaying {
                 playAnimation(animationView, playCount: playCount, isReversed: isReversed)
            }
        } else {
            animationView.stop()
        }
    }
    
    private func playAnimation(_ animationView: LottieAnimationView, playCount: Int, isReversed: Bool) {
        animationView.animationSpeed = isReversed ? -1 : 1
        
        // 注意：Lottie 有时需要先 stop 再 play 才能正确重置进度
        if !animationView.isAnimationPlaying {
            if isReversed {
                animationView.currentProgress = 1
            } else {
                animationView.currentProgress = 0
            }
            
            if playCount == 0 {
                animationView.loopMode = .loop
                animationView.play()
            } else {
                animationView.loopMode = .playOnce
                animationView.play { finished in
                    guard finished else { return }
                    if playCount > 1 {
                        self.playAnimation(animationView, playCount: playCount - 1, isReversed: isReversed)
                    }
                }
            }
        }
    }
}
