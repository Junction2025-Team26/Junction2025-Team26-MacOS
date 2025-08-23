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
    }
}

struct TextCardView: View { // Plan/Insight 공용
    let item: DashItem
    var body: some View {
        BaseCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title).font(.headline).bold()
                    Text(item.content).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                if let att = item.attachment { RightAttachmentView(attachment: att) }
            }
        }
    }
}

struct AttachmentOnlyCardView: View { // attachment 전용
    let item: DashItem
    var body: some View {
        BaseCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title).font(.headline).bold()
                    Text(item.content).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                if let att = item.attachment { RightAttachmentView(attachment: att) }
            }
        }
    }
}
