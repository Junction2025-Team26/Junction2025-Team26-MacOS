
import SwiftUI
import AppKit

@MainActor
final class DropPopoverService {
    static let shared = DropPopoverService()
    private var panel: NSPanel?

    func show(onSend: @escaping (_ text: String, _ attachment: AttachmentPayload?) -> Void) {
        if panel == nil { createPanel(onSend: onSend) }
        guard let panel else { return }

        // 현재 키 윈도우의 스크린 중앙 정렬
        let screen = NSApp.keyWindow?.screen ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        let size = NSSize(width: 420, height: 120)
        let origin = CGPoint(x: visible.midX - size.width/2,
                             y: visible.midY - size.height/2)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanel(onSend: @escaping (_ text: String, _ attachment: AttachmentPayload?) -> Void) {
        // 비활성 상태에서도 뜨는 전역 패널
        let style: NSWindow.StyleMask = [.nonactivatingPanel, .hudWindow]
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 120),
                        styleMask: style, backing: .buffered, defer: false)
        p.level = .floating
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.hidesOnDeactivate = false
        p.isMovableByWindowBackground = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // SwiftUI 컨텐츠: 기존 CapsuleInputView 재사용
        let root = PopoverCapsuleInputView(
            onSend: { text, att in
                onSend(text, att)
                self.hide()
            },
            onRejectMultiple: { /* 필요시 토스트 등 */ }
        )
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.black.opacity(0.48))
                .shadow(radius: 18, y: 8)
        )
        .frame(width: 420, height: 120)
        .onExitCommand { self.hide() }

        p.contentViewController = NSHostingController(rootView: root)
        self.panel = p
    }
}
