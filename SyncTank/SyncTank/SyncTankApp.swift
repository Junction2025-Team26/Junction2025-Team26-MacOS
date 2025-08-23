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
    
    var body: some Scene {
        Settings {
            // 빈 설정 화면 (메뉴바 전용 앱을 위해 필요)
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var animationTimer: Timer?
    var currentIconIndex: Int = 0
    var hotkeyPopover: NSPopover? // 팝오버 참조 저장
    
    // 아이콘 이름 배열
    let iconNames = ["TankIcon1", "TankIcon2", "TankIcon3"]
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 applicationDidFinishLaunching called")
        
        // 앱이 메인 윈도우을 닫아도 계속 실행되도록 설정
        NSApp.setActivationPolicy(.accessory)
        print("🚀 SyncTank app launched successfully")
        print("📱 Activation policy: accessory (menu bar only)")
        
        // 메뉴바 아이콘 생성
        print("🔧 Creating status bar item...")
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
        
        print("🔧 Creating menu...")
        statusItem?.menu = makeMenu()
        
        // 핫키 변경 시 메뉴 갱신
        print("🔧 Setting up notification observer...")
        NotificationCenter.default.addObserver(self, selector: #selector(hotKeyChanged), name: HotKeyManager.hotKeyChangedNotification, object: nil)
        print("✅ App initialization completed")
        
        // 기본 핫키 등록
        print("🔧 Registering default hotkey...")
        HotKeyManager.shared.registerSavedOrDefaultHotKey(target: self, action: #selector(showPopover))
        print("✅ Default hotkey registration completed")
        
        // 전역 명령어 설정
        setupGlobalCommands()
    }
    
    private func setupGlobalCommands() {
        print("🔧 Setting up global commands...")
        
        // 전역 명령어를 위한 메뉴 생성
        let mainMenu = NSMenu()
        
        // SyncTank 메뉴
        let syncTankMenu = NSMenu()
        let aboutItem = NSMenuItem(title: "About SyncTank", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        syncTankMenu.addItem(aboutItem)
        
        let quitItem = NSMenuItem(title: "Quit SyncTank", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        syncTankMenu.addItem(quitItem)
        
        let syncTankMenuItem = NSMenuItem(title: "SyncTank", action: nil, keyEquivalent: "")
        syncTankMenuItem.submenu = syncTankMenu
        mainMenu.addItem(syncTankMenuItem)
        
        // Quick Actions 메뉴
        let quickActionsMenu = NSMenu()
        let openPopoverItem = NSMenuItem(title: "Open Drop Popover", action: #selector(showPopover), keyEquivalent: "a")
        openPopoverItem.target = self
        quickActionsMenu.addItem(openPopoverItem)
        
        let resetPositionItem = NSMenuItem(title: "Reset Popover Position", action: #selector(resetPopoverPosition), keyEquivalent: "r")
        resetPositionItem.target = self
        quickActionsMenu.addItem(resetPositionItem)
        
        let quickActionsMenuItem = NSMenuItem(title: "Quick Actions", action: nil, keyEquivalent: "")
        quickActionsMenuItem.submenu = quickActionsMenu
        mainMenu.addItem(quickActionsMenuItem)
        
        // Hotkey Settings 메뉴
        let hotkeyMenu = NSMenu()
        let changeHotkeyItem = NSMenuItem(title: "Change Hotkey", action: #selector(changeHotkey), keyEquivalent: "h")
        changeHotkeyItem.target = self
        hotkeyMenu.addItem(changeHotkeyItem)
        
        let hotkeyMenuItem = NSMenuItem(title: "Hotkey Settings", action: nil, keyEquivalent: "")
        hotkeyMenuItem.submenu = hotkeyMenu
        mainMenu.addItem(hotkeyMenuItem)
        
        NSApp.mainMenu = mainMenu
        print("✅ Global commands setup completed")
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
        print("🖱️ Status bar button clicked")
        print("📱 Current status item: \(String(describing: statusItem))")
        
        statusItem?.menu = makeMenu()
        print("✅ Menu updated")
        
        statusItem?.button?.performClick(nil)
        print("✅ Button click performed")
    }
    
    func makeMenu() -> NSMenu {
        print("🔧 makeMenu called")
        
        let menu = NSMenu()
        
        // About SyncTank
        let aboutItem = NSMenuItem(title: "About SyncTank", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        print("✅ Added About item")
        
        menu.addItem(NSMenuItem.separator())
        
        // Open Drop Popover
        let popoverItem = NSMenuItem(title: "Open Drop Popover", action: #selector(showPopover), keyEquivalent: "")
        popoverItem.target = self
        menu.addItem(popoverItem)
        print("✅ Added Open Popover item")
        
        // 현재 핫키 표시
        let currentHotkey = HotKeyManager.shared.currentHotKeyDescription()
        let hotkeyItem = NSMenuItem(title: "Change Hotkey (\(currentHotkey))", action: #selector(changeHotkey), keyEquivalent: "")
        hotkeyItem.target = self
        menu.addItem(hotkeyItem)
        print("✅ Added Change Hotkey item: \(currentHotkey)")
        
        // Reset Popover Position
        let resetItem = NSMenuItem(title: "Reset Popover Position", action: #selector(resetPopoverPosition), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)
        print("✅ Added Reset Position item")
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        print("✅ Added Quit item")
        
        print("🎯 Menu created with \(menu.items.count) items")
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
        
        // 기존 팝오버가 열려있다면 닫기
        if let existingPopover = hotkeyPopover, existingPopover.isShown {
            existingPopover.performClose(nil)
            hotkeyPopover = nil
            return
        }
        
        let vc = HotKeyPopoverViewController()
        let popover = NSPopover()
        popover.contentViewController = vc
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 260, height: 140)
        
        // 팝오버가 닫힐 때 참조 정리
        popover.delegate = self
        
        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
            hotkeyPopover = popover
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
        print("🔄 Hotkey changed, updating menu...")
        print("📝 New hotkey: \(HotKeyManager.shared.currentHotKeyDescription())")
        
        // 메뉴바 메뉴 갱신
        statusItem?.menu = makeMenu()
        
        print("✅ Menu updated successfully")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 마지막 윈도우가 닫혀도 앱을 종료하지 않음
        return false
    }
    
    // MARK: - NSPopoverDelegate
    
    func popoverDidClose(_ notification: Notification) {
        // 팝오버가 닫힐 때 참조 정리
        hotkeyPopover = nil
        print("🔒 Hotkey popover closed")
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
