//
//  SyncTankApp.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI
import AppKit
import QuartzCore

extension Notification.Name {
    static let dropPopoverDidSend = Notification.Name("dropPopoverDidSend")
}

@main
struct SyncTankApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        HotKeyManager.shared.registerSavedOrDefaultHotKey()
    }
    
    var body: some Scene {
        Window("SyncTank", id: "main") {
            MainInsightView()   // ← 메인은 그대로. 전역 팝오버 상태 필요 없음
        }
        .defaultSize(width: 420, height: 120)
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Quick Actions") {
                Button("Open Drop Popover") {
                    DropPopoverService.shared.show { text, attachment in
                        // 전역 수신(예: NotificationCenter, 전역 Store 등으로 전달)
                        NotificationCenter.default.post(
                            name: .dropPopoverDidSend,
                            object: nil,
                            userInfo: ["text": text, "attachment": attachment as Any]
                        )
                    }
                }
                .keyboardShortcut("a", modifiers: [.option]) // ⌥ + A
                
                Button("Reset Popover Position") {
                    DropPopoverService.shared.resetPosition()
                }
                .keyboardShortcut("r", modifiers: [.option, .command]) // ⌘ + ⌥ + R
            }
            
            CommandMenu("Hotkey Settings") {
                Button("Change Hotkey") {
                    // TODO: 핫키 변경 UI 구현
                    print("Current hotkey: \(HotKeyManager.shared.currentHotKeyDescription())")
                }
                .keyboardShortcut("h", modifiers: [.option, .command]) // ⌘ + ⌥ + H
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var animationTimer: Timer?
    var currentIconIndex: Int = 0
    var hotkeyPopover: NSPopover? // 팝오버 참조 저장
    
    // 아이콘 이름 배열
    let iconNames = ["TankIcon1", "TankIcon2", "TankIcon3"]
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 앱이 메인 윈도우을 닫아도 계속 실행되도록 설정
        NSApp.setActivationPolicy(.accessory)
        print("🚀 SyncTank app launched successfully")
        print("📱 Activation policy: accessory (menu bar only)")
        print("⌨️  Current hotkey: \(HotKeyManager.shared.currentHotKeyDescription())")
        
        // 메뉴바 아이콘 생성
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            // 첫 번째 아이콘 설정
            setIcon(button: button, index: 0)
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            
            // 애니메이션 시작
            startIconAnimation(button: button)
            print("🎬 Icon animation started (1 second interval)")
        }
        statusItem?.menu = makeMenu()
        
        // 핫키 변경 시 메뉴 갱신
        NotificationCenter.default.addObserver(self, selector: #selector(hotKeyChanged), name: HotKeyManager.hotKeyChangedNotification, object: nil)
        print("✅ App initialization completed")
    }
    
    private func setIcon(button: NSStatusBarButton, index: Int) {
        let iconName = iconNames[index]
        if let icon = NSImage(named: iconName) {
            button.image = icon
            // 로그 출력을 줄여서 콘솔을 깔끔하게 유지
            // print("Icon set: \(iconName)")
        } else {
            // 아이콘이 없으면 기본 시스템 심볼 사용
            button.image = NSImage(systemSymbolName: "cylinder", accessibilityDescription: "SyncTank")
            print("Icon not found: \(iconName), using fallback")
        }
    }
    
    private func startIconAnimation(button: NSStatusBarButton) {
        // 1초마다 아이콘 변경
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.animateIcon(button: button)
        }
    }
    
    private func animateIcon(button: NSStatusBarButton) {
        // 다음 아이콘 인덱스 계산 (1→2→3→2→1→2→3 순서)
        if currentIconIndex == 0 {
            currentIconIndex = 1  // 1 → 2
        } else if currentIconIndex == 1 {
            currentIconIndex = 2  // 2 → 3
        } else if currentIconIndex == 2 {
            currentIconIndex = 1  // 3 → 2
        }
        
        // 아이콘 변경
        setIcon(button: button, index: currentIconIndex)
    }
    
    @objc func statusBarButtonClicked() {
        statusItem?.menu = makeMenu()
        statusItem?.button?.performClick(nil)
    }
    
    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        
        // About SyncTank
        let aboutItem = NSMenuItem(title: "About SyncTank", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem.separator())
        
        // Open Drop Popover
        let popoverItem = NSMenuItem(title: "Open Drop Popover", action: #selector(showPopover), keyEquivalent: "")
        popoverItem.target = self
        menu.addItem(popoverItem)
        
        // 현재 핫키 표시
        let currentHotkey = HotKeyManager.shared.currentHotKeyDescription()
        let hotkeyItem = NSMenuItem(title: "Change Hotkey (\(currentHotkey))", action: #selector(changeHotkey), keyEquivalent: "")
        hotkeyItem.target = self
        menu.addItem(hotkeyItem)
        
        // Reset Popover Position
        let resetItem = NSMenuItem(title: "Reset Popover Position", action: #selector(resetPopoverPosition), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc func showAbout() {
        let aboutView = AboutSyncTankView()
        let hosting = NSHostingController(rootView: aboutView)
        let panel = NSPanel(contentViewController: hosting)
        panel.styleMask = [.titled, .closable]
        panel.title = "About SyncTank"
        panel.setFrame(NSRect(x: 0, y: 0, width: 400, height: 300), display: true)
        panel.center()
        panel.isReleasedWhenClosed = false
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func showPopover() {
        Task { @MainActor in
            DropPopoverService.shared.show { text, attachment in
                // 전역 수신(예: NotificationCenter, 전역 Store 등으로 전달)
                NotificationCenter.default.post(
                    name: .dropPopoverDidSend,
                    object: nil,
                    userInfo: ["text": text, "attachment": attachment as Any]
                )
            }
        }
    }
    
    @objc func changeHotkey() {
        print("🔧 Opening hotkey change popover...")
        
        let vc = HotKeyPopoverViewController()
        let popover = NSPopover()
        popover.contentViewController = vc
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 260, height: 140)
        
        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
            print("✅ Hotkey change popover displayed")
        } else {
            print("❌ Failed to show popover: status item button not found")
        }
    }
    
    @objc func resetPopoverPosition() {
        Task { @MainActor in
            DropPopoverService.shared.resetPosition()
        }
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    @objc func hotKeyChanged() {
        statusItem?.menu = makeMenu()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 마지막 윈도우가 닫혀도 앱을 종료하지 않음
        return false
    }
}

struct AboutSyncTankView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tank")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .foregroundColor(.accentColor)
                .padding(.top, 24)
            
            Text("SyncTank")
                .font(.system(size: 32, weight: .bold))
                .padding(.top, 8)
            
            Text("Version 1.0")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Junction Asia 2025 - Team26")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Made by Demian Yoo")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.bottom, 24)
        }
        .frame(width: 400, height: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
