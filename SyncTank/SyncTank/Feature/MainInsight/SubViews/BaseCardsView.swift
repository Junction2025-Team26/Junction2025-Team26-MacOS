//
//  BaseCards.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

private struct BaseCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.25)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous)) // ✅
    }
}

struct ResponseCardView: View { // Plan/Insight/Attachment 공용
    let item: DashItem
    var onRemove: (DashItem) -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 카드 본문
            BaseCard {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title).font(.headline).bold()
                        Text(item.content).font(.subheadline).foregroundStyle(.secondary)
                    }
                    if let att = item.attachment {
                        Spacer(minLength: 12)
                        RightAttachmentView(attachment: att)
                    }
                }
            }
            
            // 우상단 체크 버튼 (카드 프레임 기준)
            if isHovered {
                CheckDismissButton { onRemove(item) }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .shadow(radius: 6, y: 2)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous)) // 호버 영역을 카드 모양으로
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
    }
}
