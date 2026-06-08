//
//  AppDelegate.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/6/24.
//

import AppKit
import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var cancellables = Set<AnyCancellable>()
    var appStorage = AppStorage.shared
    var iapManager = IAPManager.shared
    var sound = SoundManager.shared
    var imageArray = ImageArrayViewModel.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // 初始化键盘监听事件
        KeyboardMonitor.shared.startMonitoring()
        
        // 获取内购信息的动态数据
        Task {
            await IAPManager.shared.loadProduct()
            await IAPManager.shared.handleTransactions()
        }
        
        // 计算统计中的使用记录
        StatisticsManager.StatisticsDate()
        
        // 根据设置中的菜单栏选项，创建菜单栏
        if AppStorage.shared.displayMenuBarIcon {
            statusBarController = StatusBarController()
        }
        
        // 监听 displayMenuBarIcon 的变化
        appStorage.$displayMenuBarIcon
            .receive(on: RunLoop.main)
            .sink { [weak self] showIcon in
                guard let self = self else { return }
                if showIcon {
                    if self.statusBarController == nil {
                        self.statusBarController = StatusBarController()
                    }
                } else {
                    self.statusBarController?.removeFromStatusBar()
                    self.statusBarController = nil
                }
            }
            .store(in: &cancellables)
        
        // MARK: 创建 Window 窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 550),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                .fullSizeContentView],
            backing: .buffered,
            defer: false)
        
        window.center()
        window.isReleasedWhenClosed = false
        
        // 将标题栏改为透明样式
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        
        // 不能移动背景
        window.isMovableByWindowBackground = false
        window.minSize = NSSize(width: 650, height: 450)
        
        let rootVC = NSHostingController(rootView:
                                            MainWindowRootView(
                                                closeWindow: { [weak window] in
                                                    window?.performClose(nil)
                                                },
                                                minimizeWindow: { [weak window] in
                                                    window?.performMiniaturize(nil)
                                                },
                                                zoomWindow: { [weak window] in
                                                    window?.performZoom(nil)
                                                }
                                            )
                                                .environmentObject(appStorage)
                                                .environmentObject(iapManager)
                                                .environmentObject(sound)
                                                .environmentObject(imageArray)
        )
        
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        window.contentViewController = rootVC
        window.makeKeyAndOrderFront(nil)
        WindowManager.shared.mainWindow = window
        print("window完成初始化")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("点击Dock栏，显示window")
        if !flag {
            WindowManager.shared.mainWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("应用即将退出，清除状态栏图标")
        statusBarController?.removeFromStatusBar()
        statusBarController = nil
    }
    
    // 接收打开的图片文件
    func application(_ application: NSApplication, open urls: [URL]) {
        print("通过 application(_:open:) 接收到 URL")
        for url in urls {
            // URL Scheme 分发的事件,例如：ImageSlim://open-shared-images
            if url.scheme == "ImageSlim", url.host == "open-shared-images" {
                print("URL Scheme分发的事件")
                Task {
                    await FileProcessingService.shared.retrieveSharedImageURLs()
                }
            } else {
                // 其他分发的事件
                print("其他分发的事件")
                Task {
                    await FileProcessingService.shared.fileImporter(urls)
                }
            }
        }
    }
}


struct MainWindowRootView: View {
    let closeWindow: () -> Void
    let minimizeWindow: () -> Void
    let zoomWindow: () -> Void
    
    @State private var sidebarWidth: CGFloat = 180
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                HStack {
                    WindowControlButtons(
                        closeWindow: closeWindow,
                        minimizeWindow: minimizeWindow,
                        zoomWindow: zoomWindow
                    )
                    .padding(.leading, 18)
                    .padding(.top, 16)
                    Spacer()
                }
                MenuView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: sidebarWidth)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.85), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 24, x: 10, y: 0)
            .padding(10)
            
            ContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
        )
        .ignoresSafeArea()
    }
}

struct WindowControlButtons: View {
    let closeWindow: () -> Void
    let minimizeWindow: () -> Void
    let zoomWindow: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 10) {
            windowButton(
                color: Color(nsColor: .systemRed),
                systemImage: "xmark",
                action: closeWindow
            )
            
            windowButton(
                color: Color(nsColor: .systemYellow),
                systemImage: "minus",
                action: minimizeWindow
            )
            
            windowButton(
                color: Color(nsColor: .systemGreen),
                systemImage: "arrow.up.left.and.arrow.down.right",
                action: zoomWindow
            )
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private func windowButton(
        color: Color,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)
                
                Image(systemName: systemImage)
                    .font(.system(size: 8, weight: .black))
                    .opacity(isHovering ? 1 : 0)
            }
        }
        .buttonStyle(.plain)
    }
}
