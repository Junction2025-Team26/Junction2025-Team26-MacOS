//
//  SyncTankApp.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

extension Notification.Name {
    static let dropPopoverDidSend = Notification.Name("dropPopoverDidSend")
}

@main
struct SyncTankApp: App {
    init() {
        HotKeyManager.shared.registerOptionL()
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
                .keyboardShortcut("l", modifiers: [.option]) // ⌥ + L
            }
        }
    }
}
