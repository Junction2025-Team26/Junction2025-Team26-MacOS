import Cocoa
import Carbon.HIToolbox

class HotKeyPopoverViewController: NSViewController {
    private var isKorean: Bool {
        Locale.current.language.languageCode?.identifier == "ko"
    }
    private let currentHotKeyLabel = NSTextField(labelWithString: "")
    private let changeButton = NSButton(title: "", target: nil, action: nil)
    private let saveButton = NSButton(title: "", target: nil, action: nil)
    private var keyMonitor: Any?
    private var capturedKeyCode: UInt32?
    private var capturedModifiers: UInt32?
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
            
            let keyCode = UInt32(event.keyCode)
            let modifiers = UInt32(event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue)
            
            // 최소 하나의 수정자 키가 필요
            if modifiers == 0 {
                self.currentHotKeyLabel.stringValue = "수정자 키(⌘, ⌥, ⌃, ⇧)를 포함해야 합니다"
                self.resetCaptureState()
                return nil
            }
            
            self.capturedKeyCode = keyCode
            self.capturedModifiers = modifiers
            
            let hotkeyDescription = self.describeHotKey(keyCode: keyCode, modifiers: modifiers)
            self.currentHotKeyLabel.stringValue = self.currentHotKeyPrefix + hotkeyDescription
            
            self.resetCaptureState()
            return nil
        }
    }

    private func resetCaptureState() {
        isCapturing = false
        changeButton.isEnabled = true
        saveButton.isEnabled = true
    }

    @objc private func saveHotKey() {
        guard let keyCode = capturedKeyCode, let modifiers = capturedModifiers else { 
            print("❌ No hotkey captured")
            return 
        }
        
        print("💾 Saving hotkey: \(describeHotKey(keyCode: keyCode, modifiers: modifiers))")
        
        // HotKeyManager를 통해 새 단축키 등록
        HotKeyManager.shared.updateHotKey(keyCode: keyCode, modifiers: modifiers)
        
        // 팝오버 닫기 - 올바른 방법
        if let window = self.view.window {
            window.close()
        }
    }

    @objc private func hotKeyChanged() {
        updateHotKeyLabel()
    }

    private func describeHotKey(keyCode: UInt32, modifiers: UInt32) -> String {
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
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        case UInt32(kVK_Tab): return "Tab"
        case UInt32(kVK_Escape): return "Escape"
        case UInt32(kVK_Delete): return "Delete"
        case UInt32(kVK_ForwardDelete): return "Forward Delete"
        case UInt32(kVK_LeftArrow): return "←"
        case UInt32(kVK_RightArrow): return "→"
        case UInt32(kVK_UpArrow): return "↑"
        case UInt32(kVK_DownArrow): return "↓"
        case UInt32(kVK_F1): return "F1"
        case UInt32(kVK_F2): return "F2"
        case UInt32(kVK_F3): return "F3"
        case UInt32(kVK_F4): return "F4"
        case UInt32(kVK_F5): return "F5"
        case UInt32(kVK_F6): return "F6"
        case UInt32(kVK_F7): return "F7"
        case UInt32(kVK_F8): return "F8"
        case UInt32(kVK_F9): return "F9"
        case UInt32(kVK_F10): return "F10"
        case UInt32(kVK_F11): return "F11"
        case UInt32(kVK_F12): return "F12"
        default: return "?"
        }
    }
}
