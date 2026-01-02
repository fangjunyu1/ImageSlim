//
//  SoundManager.swift
//  ImageSlim
//
//  Created by 方君宇 on 2026/1/1.
//

import AVFoundation

@MainActor
class SoundManager:ObservableObject {
    static let shared = SoundManager() // 单例

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        preloadSounds(["success","errorSound"]) // 预加载音效
    }

    private func preloadSounds(_ soundNames: [String]) {
        for soundName in soundNames {
            if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay() // 预加载到缓存
                    players[soundName] = player
                    print("预加载音效: \(soundName)")
                } catch {
                    print("预加载失败: \(soundName), 错误: \(error.localizedDescription)")
                }
            } else {
                print("找不到音效文件: \(soundName)")
            }
        }
    }

    func playSound(named soundName: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let player = self.players[soundName] {
                player.currentTime = 0
                DispatchQueue.main.async {
                    player.play()
                }
            } else {
                print("音效未加载: \(soundName)")
            }
        }
    }
}
