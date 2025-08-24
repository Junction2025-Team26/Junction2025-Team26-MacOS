//
//  SyncTankApp.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI
import AppKit
import QuartzCore

@main
struct SyncTankApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup("SyncTank") {
            MainInsightView()
        }
        .defaultSize(width: 800, height: 600)
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Quick Actions") {
                Button("Open Drop Popover") {
                    appDelegate.showPopover()
                }
                .keyboardShortcut("a", modifiers: .option)
            }
            
            CommandMenu("Hotkey Settings") {
                Button("Change Hotkey") {
                    appDelegate.changeHotkey()
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var animationTimer: Timer?
    var currentIconIndex = 0
    let iconNames = ["TankIcon1", "TankIcon2", "TankIcon3"]
    var hotkeyPopover: NSPopover?
    
    // 전역 키보드 모니터링 추가
    private var globalKeyboardManager: KeyboardManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock과 메뉴바 모두에 표시되도록 설정
        NSApp.setActivationPolicy(.regular)
        
        // 메뉴바 아이콘 생성
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            // 첫 번째 아이콘 설정
            setIcon(button: button, index: 0)
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            
            // 애니메이션 시작
            startIconAnimation(button: button)
        }
        
        statusItem?.menu = makeMenu()
        
        // 핫키 변경 시 메뉴 갱신
        NotificationCenter.default.addObserver(self, selector: #selector(hotKeyChanged), name: HotKeyManager.hotKeyChangedNotification, object: nil)
        
        // 기본 핫키 등록
        HotKeyManager.shared.registerSavedOrDefaultHotKey(target: self, action: #selector(showPopover))
        
        // 전역 키보드 모니터링 시작
        startGlobalKeyboardMonitoring()
    }
    
    private func startGlobalKeyboardMonitoring() {
        print("⌨️ 전역 키보드 모니터링 시작")
        globalKeyboardManager = KeyboardManager()
        globalKeyboardManager?.startMonitoring { [weak self] in
            print("🎯 전역 Command+V 감지됨!")
            DispatchQueue.main.async {
                self?.handleGlobalCommandV()
            }
        }
    }
    
    private func handleGlobalCommandV() {
        print("📋 전역 Command+V 처리 시작")
        
        // 현재 활성화된 윈도우 확인
        if let keyWindow = NSApp.keyWindow {
            print("🔑 현재 키 윈도우: \(keyWindow.title)")
            
            // 팝오버가 떠있다면 팝오버에 이미지 붙여넣기
            if keyWindow.title.isEmpty || keyWindow.title == "Drop Popover" {
                print("🎯 팝오버에 이미지 붙여넣기 시도")
                // 팝오버의 이미지 붙여넣기 처리
                NotificationCenter.default.post(name: NSNotification.Name("GlobalCommandVPaste"), object: nil)
            } else if keyWindow.title == "SyncTank" {
                print("🎯 메인 윈도우에 이미지 붙여넣기 시도")
                // 메인 윈도우의 이미지 붙여넣기 처리
                NotificationCenter.default.post(name: NSNotification.Name("MainWindowCommandVPaste"), object: nil)
            }
        } else {
            print("ℹ️ 활성화된 윈도우가 없음")
        }
    }
    
    private func setIcon(button: NSStatusBarButton, index: Int) {
        let iconName = iconNames[index]
        if let icon = NSImage(named: iconName) {
            button.image = icon
        } else {
            // 아이콘이 없으면 기본 시스템 심볼 사용
            button.image = NSImage(systemSymbolName: "cylinder", accessibilityDescription: "SyncTank")
        }
    }
    
    private func startIconAnimation(button: NSStatusBarButton) {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.animateIcon(button: button)
        }
    }
    
    private func animateIcon(button: NSStatusBarButton) {
        currentIconIndex = (currentIconIndex + 1) % iconNames.count
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
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc func hotKeyChanged() {
        statusItem?.menu = makeMenu()
    }
    
    @objc func changeHotkey() {
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
        }
    }
    
    @objc func showPopover() {
        // 메인 윈도우가 떠있다면 숨기기
        if let mainWindow = NSApp.windows.first(where: { $0.title == "SyncTank" }) {
            if mainWindow.isVisible {
                print("�� 메인 윈도우 숨김 (팝오버 표시를 위해)")
                mainWindow.orderOut(nil)
            }
        }
        
        Task { @MainActor in
            DropPopoverService.shared.show { text, attachment in
                // 팝오버가 체크마크 애니메이션 후 사라짐
                // 여기서 메인 앱에 기록 저장
                self.saveToMainApp(text: text, attachment: attachment)
            }
        }
    }

    private func saveToMainApp(text: String, attachment: AttachmentPayload?) {
        print("📝 saveToMainApp 호출됨")
        // 메인 앱에 기록 저장
        print("📝 팝오버에서 전송됨: \(text)")
        if let attachment = attachment {
            print("�� 첨부파일: \(attachment.filename)")
        }
        
        // ✅ 메인 앱의 데이터 모델에 저장
        if let sharedViewModel = MainInsightView.sharedViewModel {
            // MainActor에서 실행
            Task { @MainActor in
                await sharedViewModel.sendAndReload(text: text, attachment: attachment)
                print("✅ 서버에 저장 및 fetch 완료됨")
            }
        } else {
            print("❌ InsightViewModel을 찾을 수 없음 - 정적 참조가 설정되지 않음")
        }
        
        // 팝오버가 떠있다면 먼저 강제로 숨기기 (MainActor에서 실행)
        Task { @MainActor in
            DropPopoverService.shared.forceHide()
            print("🎭 팝오버 강제 숨김 완료")
            
            // 팝오버 숨김 후 약간의 지연을 두고 메인 윈도우 표시
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 메인 윈도우가 숨겨져 있다면 다시 표시
                if let mainWindow = NSApp.windows.first(where: { $0.title == "SyncTank" }) {
                    if !mainWindow.isVisible {
                        print("🪟 메인 윈도우 재표시")
                        mainWindow.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    } else {
                        print("ℹ️ 메인 윈도우는 이미 표시됨")
                    }
                } else {
                    print("❌ 메인 윈도우를 찾을 수 없음")
                }
            }
        }
        
        print("✅ saveToMainApp 완료")
    }
    
    @objc func showAbout() {
        // About 창 표시
        NSApp.orderFrontStandardAboutPanel()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - NSPopoverDelegate
    
    func popoverDidClose(_ notification: Notification) {
        hotkeyPopover = nil
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
