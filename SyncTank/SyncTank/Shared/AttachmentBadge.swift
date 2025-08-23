//
//  AttachmentBadge.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI
import AppKit

private struct AttachmentBadge: View {
    let badge: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.fill").font(.system(size: 14))
            Text(badge).font(.caption)
        }
        .padding(.vertical, 6).padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.10)))
    }
}

struct RightAttachmentView: View {
    let attachment: AttachmentPayload
    let size = CGSize(width: 96, height: 72)

    var body: some View {
        Group {
            if attachment.isImage, let src = attachment.preview {
                PreviewImage(source: src, size: size)
            } else if let ext = attachment.fileExt {
                AttachmentBadge(badge: ext)
            }
        }
    }
}

private struct PreviewImage: View {
    let source: ImageSource
    let size: CGSize

    var body: some View {
        switch source {
        case .url(let s):
            AsyncImage(url: URL(string: s)) { phase in
                switch phase {
                case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                case .failure, .empty:  placeholder
                @unknown default:        placeholder
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped().cornerRadius(8)

        case .base64(let b64):
            if let data = Data(base64Encoded: b64), let ns = NSImage(data: data) {
                Image(nsImage: ns).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped().cornerRadius(8)
            } else { placeholder.frame(width: size.width, height: size.height) }

        case .localPath(let path):
            if let ns = NSImage(contentsOfFile: path) {
                Image(nsImage: ns).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped().cornerRadius(8)
            } else { placeholder.frame(width: size.width, height: size.height) }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.08))
            .overlay(Image(systemName: "photo").font(.system(size: 16)).foregroundStyle(.secondary))
    }
}
