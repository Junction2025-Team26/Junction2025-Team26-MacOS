
import SwiftUI
import AppKit

@MainActor
final class DropPopoverService: NSObject {
    static let shared = DropPopoverService()
    private var panel: NSPanel?
    private var escKeyMonitor: Any?
    private let popoverPanelOriginKey = "dropPopoverPanelOrigin"
    
    // MARK: - Public Methods
    
    func show(onSend: @escaping (_ text: String, _ attachment: AttachmentPayload?) -> Void) {
        if let panel = panel, panel.isVisible {
            hide()
            return
        }
        
        createPanel(onSend: onSend)
        setupPanelPosition()
        startESCKeyMonitoring()
        
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // 즉시 포커스 설정 (타이밍 단축)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.forceFocus()
        }
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
        stopESCKeyMonitoring()
    }
    
    func cleanup() {
        hide()
    }
    
    func resetPosition() {
        UserDefaults.standard.removeObject(forKey: popoverPanelOriginKey)
        if let panel = panel, panel.isVisible {
            // 현재 표시 중인 팝오버의 위치를 화면 중앙으로 이동
            let screen = NSApp.keyWindow?.screen ?? NSScreen.main
            let visible = screen?.visibleFrame ?? .zero
            let size = panel.frame.size
            let origin = CGPoint(x: visible.midX - size.width/2,
                                 y: visible.midY - size.height/2)
            panel.setFrame(NSRect(origin: origin, size: size), display: true)
        }
    }
    
    // MARK: - Private Methods
    
    private func createPanel(onSend: @escaping (_ text: String, _ attachment: AttachmentPayload?) -> Void) {
        let style: NSWindow.StyleMask = [.titled, .fullSizeContentView]
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 120),
                        styleMask: style, backing: .buffered, defer: false)
        
        // 패널 설정 - 키 윈도우가 될 수 있도록 수정
        p.isFloatingPanel = true
        p.level = .floating
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.hasShadow = false
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hidesOnDeactivate = true  // 외부 클릭 시 자동으로 닫히도록 설정
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isMovableByWindowBackground = true
        
        // 윈도우 버튼 숨기기
        p.standardWindowButton(.closeButton)?.isHidden = true
        p.standardWindowButton(.miniaturizeButton)?.isHidden = true
        p.standardWindowButton(.zoomButton)?.isHidden = true
        
        // SwiftUI 컨텐츠
        let root = PopoverCapsuleInputView(
            onSend: { text, att in
                print("🎯 PopoverCapsuleInputView onSend called: \(text)")
                if let attachment = att {
                    print("📎 Attachment: \(attachment.filename)")
                }
                // 체크 모양의 원형으로 줄어들면서 사라지는 애니메이션
                self.animateToCheckmarkAndClose(text: text, attachment: att, onSend: onSend)
            },
            onRejectMultiple: { /* 필요시 토스트 등 */ }
        )

        .frame(width: 420, height: 120)
        .onExitCommand { self.hide() }
        
        let hostingController = NSHostingController(rootView: root)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 420, height: 120)
        hostingController.view.wantsLayer = true
        
        p.contentView = hostingController.view
        panel = p
    }
    
    private func animateToCheckmarkAndClose(text: String, attachment: AttachmentPayload?, onSend: @escaping (_ text: String, _ attachment: AttachmentPayload?) -> Void) {
        print("🎬 animateToCheckmarkAndClose 시작: \(text)")
        guard let panel = panel else { 
            print("❌ Panel이 nil입니다")
            return 
        }
        
        // 체크 모양의 원형 뷰로 교체
        let checkmarkView = CheckmarkView()
        let hostingController = NSHostingController(rootView: checkmarkView)
        
        // 체크마크 뷰를 작은 크기로 만들어서 가운데에 배치
        let checkmarkSize = NSSize(width: 120, height: 120)
        let currentFrame = panel.frame
        let newOrigin = CGPoint(
            x: currentFrame.origin.x + (currentFrame.width - checkmarkSize.width) / 2,
            y: currentFrame.origin.y + (currentFrame.height - checkmarkSize.height) / 2
        )
        
        hostingController.view.frame = NSRect(origin: .zero, size: checkmarkSize)
        hostingController.view.wantsLayer = true
        
        // 컨텐츠를 체크마크 뷰로 교체하고 패널 크기 조정
        panel.contentView = hostingController.view
        panel.setFrame(NSRect(origin: newOrigin, size: checkmarkSize), display: true)
        print("✅ 체크마크 뷰로 교체 완료")
        
        // 체크마크가 나타난 후 페이드 아웃으로 사라짐
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🎬 페이드 아웃 애니메이션 시작")
            
            // 페이드 아웃 애니메이션
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                // 투명도 애니메이션
                panel.animator().alphaValue = 0.0
            }) {
                print("✅ 페이드 아웃 완료")
                print("🎯 onSend 콜백 호출: \(text)")
                // 메인 앱에 기록 전달
                onSend(text, attachment)
                print("✅ onSend 콜백 완료")
                self.hide()
            }
        }
    }
    
    private func setupPanelPosition() {
        guard let panel = panel else { return }
        
        let size = NSSize(width: 420, height: 120)
        
        // 저장된 위치가 있으면 사용, 없으면 화면 중앙
        if let originString = UserDefaults.standard.string(forKey: popoverPanelOriginKey) {
            let origin = NSPointFromString(originString)
            panel.setFrame(NSRect(origin: origin, size: size), display: true)
        } else {
            let screen = NSApp.keyWindow?.screen ?? NSScreen.main
            let visible = screen?.visibleFrame ?? .zero
            let origin = CGPoint(x: visible.midX - size.width/2,
                                 y: visible.midY - size.height/2)
            panel.setFrame(NSRect(origin: origin, size: size), display: true)
        }
    }
    
    private func startESCKeyMonitoring() {
        // ESC 키 모니터링
        escKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC 키
                DispatchQueue.main.async {
                    self?.hide()
                }
                return nil
            }
            return event
        }
    }
    
    private func stopESCKeyMonitoring() {
        if let monitor = escKeyMonitor {
            NSEvent.removeMonitor(monitor)
            escKeyMonitor = nil
        }
    }
    
    private func forceFocus() {
        guard let panel = panel else { return }
        
        print("Force focus started for panel: \(panel)")
        print("Panel canBecomeKey: \(panel.canBecomeKey)")
        print("Panel isKeyWindow: \(panel.isKeyWindow)")
        
        // 방법 1: 패널을 키 윈도우로 만들기
        panel.makeKeyAndOrderFront(nil)
        print("Panel makeKeyAndOrderFront called")
        
        // 방법 2: 즉시 TextField 찾기 및 포커스 설정
        if let hostingController = panel.contentViewController as? NSHostingController<PopoverCapsuleInputView> {
            // 즉시 TextField 찾기 시도
            if let textField = self.findTextField(in: hostingController.view) {
                panel.makeFirstResponder(textField)
                print("TextField found and focused immediately: \(textField)")
            } else {
                // TextField를 찾을 수 없으면 약간의 지연 후 재시도
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if let textField = self.findTextField(in: hostingController.view) {
                        panel.makeFirstResponder(textField)
                        print("TextField found and focused on retry: \(textField)")
                    } else {
                        print("TextField not found after retry")
                    }
                }
            }
        }
        
        // 방법 3: NSApp 활성화
        NSApp.activate(ignoringOtherApps: true)
        
        print("Force focus completed")
    }
    
    private func findTextField(in view: NSView) -> NSTextField? {
        // NSView에서 NSTextField를 재귀적으로 찾기
        if let textField = view as? NSTextField {
            return textField
        }
        
        for subview in view.subviews {
            if let textField = findTextField(in: subview) {
                return textField
            }
        }
        
        return nil
    }
}

// MARK: - NSWindowDelegate
extension DropPopoverService: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window == panel else { return }
        
        let originString = NSStringFromPoint(window.frame.origin)
        UserDefaults.standard.set(originString, forKey: popoverPanelOriginKey)
    }
    
    func windowWillClose(_ notification: Notification) {
        hide()
    }
}
