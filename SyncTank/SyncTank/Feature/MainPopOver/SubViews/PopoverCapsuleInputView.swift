//
//  PopoverCapsuleInputView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

/// 전역 팝오버에서 쓰는 래퍼: 내부 상태 관리 → (text, attachment) 콜백만 밖으로
struct PopoverCapsuleInputView: View {
    var onSend: (_ text: String, _ attachment: AttachmentPayload?) -> Void
    var onRejectMultiple: () -> Void = {}

    @State private var text: String = ""
    @State private var pendingAttachment: AttachmentPayload? = nil
    @State private var pendingFileName: String? = nil
    @FocusState private var focused: Bool

    var body: some View {
        CapsuleInputView(
            text: $text,
            pendingAttachment: $pendingAttachment,
            pendingFileName: $pendingFileName,
            onSend: {
                onSend(text, pendingAttachment)
                text = ""; pendingAttachment = nil; pendingFileName = nil
            },
            onRejectMultiple: onRejectMultiple
        )
        .focused($focused)
        .onAppear { focused = true } // 열리자마자 커서 포커스
    }
}
