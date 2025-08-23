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
        print("🔧 registerSavedOrDefaultHotKey called with target: \(target), action: \(action)")
        
        if let (key, modifiers) = loadHotKeyFromUserDefaults() {
            print("📱 Found saved hotkey in UserDefaults")
            registerHotKey(key: key, modifiers: modifiers, target: target, action: action)
        } else {
            print("❌ No saved hotkey found, registering default")
            registerDefaultHotKey(target: target, action: action)
        }
    }
    
    func updateHotKey(key: Key, modifiers: NSEvent.ModifierFlags, target: AnyObject, action: Selector) {
        print("🔧 updateHotKey called")
        unregister()
        registerHotKey(key: key, modifiers: modifiers, target: target, action: action)
        saveHotKeyToUserDefaults(key: key, modifiers: modifiers)
        NotificationCenter.default.post(name: HotKeyManager.hotKeyChangedNotification, object: nil)
    }
    
    func registerDefaultHotKey(target: AnyObject, action: Selector) {
        print("🔧 registerDefaultHotKey called with target: \(target), action: \(action)")
        
        // 기본값: ⌥ + A
        let key: Key = .a
        let modifiers: NSEvent.ModifierFlags = [.option]
        
        print("📝 Default hotkey - key: \(key), modifiers: \(modifiers)")
        
        registerHotKey(key: key, modifiers: modifiers, target: target, action: action)
        
        // 기본 핫키를 UserDefaults에 저장
        saveHotKeyToUserDefaults(key: key, modifiers: modifiers)
        
        print("✅ Default hotkey registered and saved to UserDefaults")
    }
    
    func unregister() {
        print("🔧 unregister called")
        hotKey = nil
        keyCombo = nil
        print("🧹 Unregister completed")
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
        print("🔧 registerHotKey called")
        print("📝 Parameters - key: \(key), modifiers: \(modifiers)")
        print("🎯 Target: \(target), Action: \(action)")
        
        unregister()
        
        let combo = KeyCombo(key: key, modifiers: modifiers)
        keyCombo = combo
        hotKey = HotKey(keyCombo: combo)
        
        hotKey?.keyDownHandler = { [weak target] in
            print("🎯 Hotkey callback triggered!")
            print("📋 Key combo: \(combo)")
            
            DispatchQueue.main.async {
                if let target = target {
                    print("🎯 Executing action on target: \(target)")
                    _ = target.perform(action)
                } else {
                    print("❌ Target is nil")
                }
            }
        }
        
        print("✅ HotKey registered successfully")
        print("📊 Final status:")
        print("  - KeyCombo: \(combo)")
        print("  - HotKey: \(String(describing: hotKey))")
    }
    
    private func saveHotKeyToUserDefaults(key: Key, modifiers: NSEvent.ModifierFlags) {
        print("💾 saveHotKeyToUserDefaults called")
        print("📝 Saving - key: \(key), modifiers: \(modifiers)")
        print("🔑 UserDefaults key: \(hotKeyUserDefaultsKey)")
        
        let dict: [String: Any] = [
            "key": key.description,
            "modifiers": modifiers.rawValue
        ]
        
        UserDefaults.standard.set(dict, forKey: hotKeyUserDefaultsKey)
        
        // 저장 확인
        if let savedDict = UserDefaults.standard.dictionary(forKey: hotKeyUserDefaultsKey) {
            print("✅ Successfully saved to UserDefaults: \(savedDict)")
        } else {
            print("❌ Failed to save to UserDefaults")
        }
    }
    
    private func loadHotKeyFromUserDefaults() -> (Key, NSEvent.ModifierFlags)? {
        print("🔍 loadHotKeyFromUserDefaults called")
        print("🔑 UserDefaults key: \(hotKeyUserDefaultsKey)")
        
        guard let dict = UserDefaults.standard.dictionary(forKey: hotKeyUserDefaultsKey) else {
            print("❌ No dictionary found in UserDefaults")
            return nil
        }
        
        print("📱 Dictionary found: \(dict)")
        
        guard let keyString = dict["key"] as? String else {
            print("❌ key not found or wrong type")
            return nil
        }
        
        guard let modifiersRaw = dict["modifiers"] as? UInt else {
            print("❌ modifiers not found or wrong type")
            return nil
        }
        
        guard let key = Key(string: keyString) else {
            print("❌ Failed to create Key from string: \(keyString)")
            return nil
        }
        
        let modifiers = NSEvent.ModifierFlags(rawValue: modifiersRaw)
        
        print("✅ Successfully loaded - key: \(key), modifiers: \(modifiers)")
        return (key, modifiers)
    }
}
