//
//  Untitled.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ComposerAttachmentChip: View {
    let attachment: AttachmentPayload
    let fileName: String?
    var onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // 썸네일 또는 아이콘
            if attachment.isImage == true, let src = attachment.preview {
                ThumbFromImageSource(source: src)
                    .frame(width: 36, height: 28)
                    .clipped()
                    .cornerRadius(6)
            } else {
                Text((attachment.fileExt ?? "FILE").uppercased())
                    .font(.caption2).bold().monospaced()
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
            }
            
            // 파일명
            Text(fileName ?? (attachment.fileExt ?? "Attachment"))
                .font(.system(size: 12))
                .lineLimit(1)
                .foregroundStyle(.secondary)
            
            // 제거 버튼
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
    }
}
