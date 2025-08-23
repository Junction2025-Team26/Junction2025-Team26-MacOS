import Cocoa
import HotKey

class HotKeyPopoverViewController: NSViewController {
    private var isKorean: Bool {
        Locale.current.language.languageCode?.identifier == "ko"
    }
    private let currentHotKeyLabel = NSTextField(labelWithString: "")
    private let changeButton = NSButton(title: "", target: nil, action: nil)
    private let saveButton = NSButton(title: "", target: nil, action: nil)
    private var keyMonitor: Any?
    private var capturedKey: Key?
    private var capturedModifiers: NSEvent.ModifierFlags?
    private var isCapturing = false
    private var currentHotKeyPrefix: String { isKorean ? "현재 단축키: " : "Current Hotkey: " }
    private var inputGuideText: String { isKorean ? "새 단축키를 입력하세요..." : "Enter new hotkey..." }
    private var changeButtonTitle: String { isKorean ? "변경" : "Change" }
    private var saveButtonTitle: String { isKorean ? "저장" : "Save" }
    private var unsupportedKeyText: String { isKorean ? "지원하지 않는 키입니다. 다시 시도하세요." : "Unsupported key. Try again." }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 120))
        currentHotKeyLabel.alignment = .center
        currentHotKeyLabel.font = NSFont.systemFont(ofSize: 15, weight: .medium)
        currentHotKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        changeButton.setButtonType(.momentaryPushIn)
        saveButton.setButtonType(.momentaryPushIn)
        changeButton.font = NSFont.systemFont(ofSize: 13)
        saveButton.font = NSFont.systemFont(ofSize: 13)
        changeButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        changeButton.title = changeButtonTitle
        saveButton.title = saveButtonTitle
        // 버튼 그룹 StackView
        let buttonStack = NSStackView(views: [changeButton, saveButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 16
        buttonStack.alignment = .centerX
        buttonStack.distribution = .equalCentering
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        // 전체 StackView
        let mainStack = NSStackView(views: [currentHotKeyLabel, buttonStack])
        mainStack.orientation = .vertical
        mainStack.spacing = 18
        mainStack.alignment = .centerX
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])
        updateHotKeyLabel()
        changeButton.target = self
        changeButton.action = #selector(beginKeyCapture)
        saveButton.target = self
        saveButton.action = #selector(saveHotKey)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 레이아웃 설정을 한 번만 수행
        DispatchQueue.main.async {
            self.updateHotKeyLabel()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(hotKeyChanged), name: HotKeyManager.hotKeyChangedNotification, object: nil)
    }
    
    deinit {
        // 키 모니터 정리
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // 노티피케이션 옵저버 제거
        NotificationCenter.default.removeObserver(self)
        
        print("🧹 HotKeyPopoverViewController deallocated")
    }

    private func updateHotKeyLabel() {
        currentHotKeyLabel.stringValue = currentHotKeyPrefix + HotKeyManager.shared.currentHotKeyDescription()
        currentHotKeyLabel.alignment = .center
    }

    @objc private func beginKeyCapture() {
        isCapturing = true
        currentHotKeyLabel.stringValue = inputGuideText
        currentHotKeyLabel.alignment = .center
        changeButton.isEnabled = false
        saveButton.isEnabled = false
        
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            // 모니터 제거
            if let monitor = self.keyMonitor {
                NSEvent.removeMonitor(monitor)
                self.keyMonitor = nil
            }
            
            if let key = Key(carbonKeyCode: UInt32(event.keyCode)) {
                let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                
                // 최소 하나의 수정자 키가 필요
                if !modifiers.contains(.option) && !modifiers.contains(.control) && 
                   !modifiers.contains(.shift) && !modifiers.contains(.command) {
                    self.currentHotKeyLabel.stringValue = "수정자 키(⌘, ⌥, ⌃, ⇧)를 포함해야 합니다"
                    self.resetCaptureState()
                    return nil
                }
                
                self.capturedKey = key
                self.capturedModifiers = modifiers
                
                let hotkeyDescription = self.describeHotKey(key: key, modifiers: modifiers)
                self.currentHotKeyLabel.stringValue = self.currentHotKeyPrefix + hotkeyDescription
                
                self.resetCaptureState()
            } else {
                self.currentHotKeyLabel.stringValue = self.unsupportedKeyText
                self.resetCaptureState()
            }
            
            return nil
        }
    }

    private func resetCaptureState() {
        isCapturing = false
        changeButton.isEnabled = true
        saveButton.isEnabled = true
    }

    @objc private func saveHotKey() {
        guard let key = capturedKey, let modifiers = capturedModifiers else { 
            print("❌ No hotkey captured")
            return 
        }
        
        print("💾 Saving hotkey: \(describeHotKey(key: key, modifiers: modifiers))")
        
        // HotKeyManager를 통해 새 단축키 등록
        HotKeyManager.shared.updateHotKey(key: key, modifiers: modifiers, target: NSApp.delegate as AnyObject, action: #selector(AppDelegate.showPopover))
        
        // 메뉴바 갱신을 위한 노티피케이션 전송
        NotificationCenter.default.post(name: HotKeyManager.hotKeyChangedNotification, object: nil)
        
        print("✅ Hotkey saved, closing popover...")
        
        // 팝오버 닫기 - 부모 윈도우를 통해 닫기
        if let window = self.view.window {
            window.close()
        }
        
        print("🔒 Popover closed")
    }

    @objc private func hotKeyChanged() {
        updateHotKeyLabel()
    }

    private func describeHotKey(key: Key, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        
        parts.append(key.description)
        
        return parts.joined(separator: " + ")
    }
}
