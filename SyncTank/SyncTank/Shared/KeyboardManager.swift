//
//  KeyboardManager.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import Foundation
import AppKit

class KeyboardManager {
    private var keyMonitor: Any?
    private var onCommandV: (() -> Void)?
    
    func startMonitoring(onCommandV: @escaping () -> Void) {
        // 이미 모니터링 중이면 중복 등록 방지
        if keyMonitor != nil {
            print("⌨️ 이미 키보드 모니터링 중입니다")
            return
        }
        
        self.onCommandV = onCommandV
        print("⌨️ KeyboardManager 모니터링 시작")
        
        // NSEvent 모니터링 시작
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            print("🎯 키보드 이벤트 감지됨: \(event.keyCode)")
            
            // Command+V 감지 (V 키는 keyCode 9)
            if event.modifierFlags.contains(.command) && event.keyCode == 9 {
                print("🎯 Command+V 감지됨!")
                // 메인 스레드에서 콜백 실행
                DispatchQueue.main.async {
                    self.onCommandV?()
                }
                return nil // 이벤트 소비
            }
            return event
        }
    }
    
    func stopMonitoring() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
            onCommandV = nil
            print("⌨️ KeyboardManager 모니터링 중지")
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
