//
//  HotkeyManager.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import Cocoa
import Carbon.HIToolbox

final class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    func registerOptionL() {
        // 이미 등록돼 있으면 중복 방지
        unregister()

        // ⌥ + L
        let keyCode: UInt32 = UInt32(kVK_ANSI_L)
        let modifiers: UInt32 = UInt32(optionKey)

        var hotKeyID = EventHotKeyID(signature: OSType("STHK".fourCC),
                                     id: 1)
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        // 콜백: 핫키 눌렸을 때 실행
        let callback: EventHandlerUPP = { _, eventRef, userData in
            var hkID = EventHotKeyID()
            GetEventParameter(eventRef,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hkID)

            if hkID.signature == OSType("STHK".fourCC), hkID.id == 1 {
                DispatchQueue.main.async {
                    DropPopoverService.shared.show { text, att in
                        // 전송 시에 하고 싶은 처리
                        // 예: ViewModel에 추가/서버 업로드 등
                        print("Popover send: \(text), att=\(String(describing: att))")
                    }
                }
            }
            return noErr
        }

        // 핫키 이벤트 핸들러 설치
        InstallEventHandler(GetEventDispatcherTarget(),
                            callback,
                            1,
                            [eventType],
                            nil,
                            &eventHandlerRef)

        // 핫키 등록
        RegisterEventHotKey(keyCode,
                            modifiers,
                            hotKeyID,
                            GetEventDispatcherTarget(),
                            0,
                            &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let h = eventHandlerRef {
            RemoveEventHandler(h)
            eventHandlerRef = nil
        }
    }
}

private extension OSType {
    init(_ s: String) {
        var result: UInt32 = 0
        for char in s.utf8.prefix(4) {
            result = (result << 8) + UInt32(char)
        }
        self.init(result)
    }
}
private extension String { var fourCC: UInt32 { OSType(self) } }
