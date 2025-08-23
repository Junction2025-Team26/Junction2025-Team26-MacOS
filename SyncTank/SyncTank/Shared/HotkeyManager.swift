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
    static let hotKeyChangedNotification = Notification.Name("HotKeyChanged")
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeyUserDefaultsKey = "userHotKey"
    
    // MARK: - Public Methods
    
    func registerSavedOrDefaultHotKey() {
        if let (keyCode, modifiers) = loadHotKeyFromUserDefaults() {
            registerHotKey(keyCode: keyCode, modifiers: modifiers)
        } else {
            registerDefaultHotKey()
        }
    }
    
    func updateHotKey(keyCode: UInt32, modifiers: UInt32) {
        unregister()
        registerHotKey(keyCode: keyCode, modifiers: modifiers)
        saveHotKeyToUserDefaults(keyCode: keyCode, modifiers: modifiers)
        NotificationCenter.default.post(name: HotKeyManager.hotKeyChangedNotification, object: nil)
    }
    
    func registerDefaultHotKey() {
        // 기본값: ⌥ + A
        let keyCode: UInt32 = UInt32(kVK_ANSI_A)
        let modifiers: UInt32 = UInt32(optionKey)
        registerHotKey(keyCode: keyCode, modifiers: modifiers)
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
    
    func currentHotKeyDescription() -> String {
        if let (keyCode, modifiers) = loadHotKeyFromUserDefaults() {
            return formatHotKeyDescription(keyCode: keyCode, modifiers: modifiers)
        } else {
            return "⌥ + A"
        }
    }
    
    // MARK: - Private Methods
    
    private func registerHotKey(keyCode: UInt32, modifiers: UInt32) {
        unregister()
        
        var hotKeyID = EventHotKeyID(signature: OSType("STHK".fourCC), id: 1)
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        
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
    
    private func saveHotKeyToUserDefaults(keyCode: UInt32, modifiers: UInt32) {
        let dict: [String: Any] = [
            "keyCode": keyCode,
            "modifiers": modifiers
        ]
        UserDefaults.standard.set(dict, forKey: hotKeyUserDefaultsKey)
    }
    
    private func loadHotKeyFromUserDefaults() -> (UInt32, UInt32)? {
        guard let dict = UserDefaults.standard.dictionary(forKey: hotKeyUserDefaultsKey),
              let keyCode = dict["keyCode"] as? UInt32,
              let modifiers = dict["modifiers"] as? UInt32 else { return nil }
        return (keyCode, modifiers)
    }
    
    private func formatHotKeyDescription(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        
        let keyName = getKeyName(keyCode: keyCode)
        parts.append(keyName)
        
        return parts.joined(separator: " + ")
    }
    
    private func getKeyName(keyCode: UInt32) -> String {
        switch keyCode {
        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_B): return "B"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_D): return "D"
        case UInt32(kVK_ANSI_E): return "E"
        case UInt32(kVK_ANSI_F): return "F"
        case UInt32(kVK_ANSI_G): return "G"
        case UInt32(kVK_ANSI_H): return "H"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_J): return "J"
        case UInt32(kVK_ANSI_K): return "K"
        case UInt32(kVK_ANSI_L): return "L"
        case UInt32(kVK_ANSI_M): return "M"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_O): return "O"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_Q): return "Q"
        case UInt32(kVK_ANSI_R): return "R"
        case UInt32(kVK_ANSI_S): return "S"
        case UInt32(kVK_ANSI_T): return "T"
        case UInt32(kVK_ANSI_U): return "U"
        case UInt32(kVK_ANSI_V): return "V"
        case UInt32(kVK_ANSI_W): return "W"
        case UInt32(kVK_ANSI_X): return "X"
        case UInt32(kVK_ANSI_Y): return "Y"
        case UInt32(kVK_ANSI_Z): return "Z"
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        case UInt32(kVK_Tab): return "Tab"
        case UInt32(kVK_Escape): return "Esc"
        case UInt32(kVK_Delete): return "Delete"
        case UInt32(kVK_ForwardDelete): return "Forward Delete"
        case UInt32(kVK_LeftArrow): return "←"
        case UInt32(kVK_RightArrow): return "→"
        case UInt32(kVK_UpArrow): return "↑"
        case UInt32(kVK_DownArrow): return "↓"
        case UInt32(kVK_ANSI_0): return "0"
        case UInt32(kVK_ANSI_1): return "1"
        case UInt32(kVK_ANSI_2): return "2"
        case UInt32(kVK_ANSI_3): return "3"
        case UInt32(kVK_ANSI_4): return "4"
        case UInt32(kVK_ANSI_5): return "5"
        case UInt32(kVK_ANSI_6): return "6"
        case UInt32(kVK_ANSI_7): return "7"
        case UInt32(kVK_ANSI_8): return "8"
        case UInt32(kVK_ANSI_9): return "9"
        default: return "?"
        }
    }
}

// MARK: - Extensions
private extension OSType {
    init(_ s: String) {
        var result: UInt32 = 0
        for char in s.utf8.prefix(4) {
            result = (result << 8) + UInt32(char)
        }
        self.init(result)
    }
}

private extension String { 
    var fourCC: UInt32 { OSType(self) } 
}
