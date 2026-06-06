//
//  KeyboardMonitor.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/15.
//

import AppKit
import Combine

class KeyboardMonitor: ObservableObject {
    static let shared = KeyboardMonitor()

    private var monitor: Any?
    let pastePublisher = PassthroughSubject<Void, Never>()

    func startMonitoring() {
        print("进入 startMonitoring 方法")
        guard monitor == nil else { return } // 防止重复添加
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.command),
               event.charactersIgnoringModifiers == "v" {
                self?.pastePublisher.send()
                return nil // 拦截系统 ⌘V，使用return nil，如果想保留系统粘贴，就 return event
            }
            return event
        }
    }

    deinit {
        print("取消初始化")
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
