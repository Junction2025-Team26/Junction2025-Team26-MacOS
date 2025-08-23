//
//  HotkeyManager.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import Foundation
import HotKey
import AppKit

final class HotKeyManager {
    static let shared = HotKeyManager()
    static let hotKeyChangedNotification = Notification.Name("HotKeyManagerHotKeyChanged")

    private var hotKey: HotKey?
    private(set) var keyCombo: KeyCombo? = nil
    private let hotKeyUserDefaultsKey = "userHotKey"

    // MARK: - Public Methods
    
    func registerSavedOrDefaultHotKey(target: AnyObject, action: Selector) {
        if let (key, modifiers) = loadHotKeyFromUserDefaults() {
            registerHotKey(key: key, modifiers: modifiers, target: target, action: action)
        } else {
            registerDefaultHotKey(target: target, action: action)
        }
    }
    
    func updateHotKey(key: Key, modifiers: NSEvent.ModifierFlags, target: AnyObject, action: Selector) {
        unregister()
        registerHotKey(key: key, modifiers: modifiers, target: target, action: action)
        saveHotKeyToUserDefaults(key: key, modifiers: modifiers)
        NotificationCenter.default.post(name: HotKeyManager.hotKeyChangedNotification, object: nil)
    }
    
    func registerDefaultHotKey(target: AnyObject, action: Selector) {
        // 기본값: ⌥ + A
        let key: Key = .a
        let modifiers: NSEvent.ModifierFlags = [.option]
        
        registerHotKey(key: key, modifiers: modifiers, target: target, action: action)
        
        // 기본 핫키를 UserDefaults에 저장
        saveHotKeyToUserDefaults(key: key, modifiers: modifiers)
    }
    
    func unregister() {
        hotKey = nil
        keyCombo = nil
    }
    
    func currentHotKeyDescription() -> String {
        if let combo = keyCombo {
            var parts: [String] = []
            if combo.modifiers.contains(.command) { parts.append("⌘") }
            if combo.modifiers.contains(.option) { parts.append("⌥") }
            if combo.modifiers.contains(.shift) { parts.append("⇧") }
            if combo.modifiers.contains(.control) { parts.append("⌃") }
            if let key = combo.key {
                parts.append(key.description)
            } else {
                parts.append("?")
            }
            return parts.joined(separator: " + ")
        } else {
            return "⌥ + A"
        }
    }
    
    // MARK: - Private Methods
    
    private func registerHotKey(key: Key, modifiers: NSEvent.ModifierFlags, target: AnyObject, action: Selector) {
        unregister()
        
        let combo = KeyCombo(key: key, modifiers: modifiers)
        keyCombo = combo
        hotKey = HotKey(keyCombo: combo)
        
        hotKey?.keyDownHandler = { [weak target] in
            
            DispatchQueue.main.async {
                if let target = target {
                    _ = target.perform(action)
                }
            }
        }
    }
    
    private func saveHotKeyToUserDefaults(key: Key, modifiers: NSEvent.ModifierFlags) {
        let dict: [String: Any] = [
            "key": key.description,
            "modifiers": modifiers.rawValue
        ]
        
        UserDefaults.standard.set(dict, forKey: hotKeyUserDefaultsKey)
    }
    
    private func loadHotKeyFromUserDefaults() -> (Key, NSEvent.ModifierFlags)? {
        guard let dict = UserDefaults.standard.dictionary(forKey: hotKeyUserDefaultsKey) else {
            return nil
        }
        
        guard let keyString = dict["key"] as? String else {
            return nil
        }
        
        guard let modifiersRaw = dict["modifiers"] as? UInt else {
            return nil
        }
        
        guard let key = Key(string: keyString) else {
            return nil
        }
        
        let modifiers = NSEvent.ModifierFlags(rawValue: modifiersRaw)
        
        return (key, modifiers)
    }
}
