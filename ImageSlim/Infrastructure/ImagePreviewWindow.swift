//
//  ImagePreviewWindow.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//

import AppKit
import SwiftUI

class ImagePreviewWindow {
    private var window: NSWindow?
    
    func show(image: Image) {
        let hostingViewController = NSHostingController(rootView:
                                            image
            .resizable()
            .scaledToFit()
            .frame(minWidth: 400, minHeight: 400)
            .padding()
        )
        
        let window = NSWindow(contentViewController: hostingViewController)
        
        window.title = "Image Preview"
        window.setContentSize(NSSize(width: 600, height: 600))
        window.styleMask = [.titled, .closable, .resizable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}
