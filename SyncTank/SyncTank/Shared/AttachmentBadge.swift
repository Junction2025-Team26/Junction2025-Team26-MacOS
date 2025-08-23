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
    
    var body: some View {
        Group {
            if attachment.isImage, let src = attachment.preview {
                ThumbFromImageSource(source: src)
                    .frame(width: 96, height: 72)
                    .clipped()
                    .cornerRadius(8)
            } else {
                // 파일 배지
                HStack(spacing: 8) {
                    Image(systemName: "doc.fill").font(.system(size: 14))
                    Text((attachment.fileExt ?? "FILE").uppercased())
                        .font(.caption).monospaced()
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
            }
        }
    }
}

struct ThumbFromImageSource: View {
    let source: ImageSource
    var body: some View {
        switch source {
        case .url(let s):
            // 간단히 URL만 있는 경우: SwiftUI AsyncImage
            if let url = URL(string: s) {
                AsyncImage(url: url) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Color.gray.opacity(0.2)
            }
        case .base64(let b64):
            if let data = Data(base64Encoded: b64), let nsimg = NSImage(data: data) {
                Image(nsImage: nsimg).resizable().aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.2)
            }
        case .localPath(let path):
            let fileURL = URL(fileURLWithPath: path)
            if let nsimg = NSImage(contentsOf: fileURL) {        // ✅ contentsOf: URL
                Image(nsImage: nsimg).resizable().aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.2)
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
