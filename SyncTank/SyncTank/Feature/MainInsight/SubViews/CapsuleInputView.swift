//
//  CapsuleInputView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//
import SwiftUI
import UniformTypeIdentifiers

struct CapsuleInputView: View {
    @Binding var text: String
    @Binding var pendingAttachment: AttachmentPayload?
    @Binding var pendingFileName: String?
    
    var onSend: () -> Void = { }
    var onRejectMultiple: () -> Void = { }
    
    @State private var isDropTargeted = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                if let att = pendingAttachment {
                    ComposerAttachmentChip(attachment: att, fileName: pendingFileName) {
                        pendingAttachment = nil
                        pendingFileName = nil
                    }
                }
                
                // 텍스트는 항상 존재
                CapsulePlaceHolderView(text: $text) { _ in
                    onSend()
                }
            }
            .padding(.leading, 16)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 30))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
        }
        .padding(.vertical, 12)
        .frame(width: Metrics.capsuleWidth)
        .background(
            RoundedRectangle(cornerRadius: Metrics.capsuleCorner, style: .continuous)
                .fill(Color("CapsuleColor"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.capsuleCorner, style: .continuous)
                .stroke(Color.white, lineWidth: 1)
        )
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            guard providers.count == 1, pendingAttachment == nil else {
                onRejectMultiple()
                return true
            }
            let provider = providers.first!
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                
                // 보안-스코프 접근 열기
                let opened = url.startAccessingSecurityScopedResource()
                defer { if opened { url.stopAccessingSecurityScopedResource() } }
                
                let ext = url.pathExtension.uppercased()
                let isImage = (UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) ?? false)
                
                DispatchQueue.main.async {
                    if isImage {
                        pendingAttachment = AttachmentPayload(
                            isImage: true,
                            fileExt: ext,
                            preview: .localPath(url.path), // 아래 2번과 세트
                            fileURLString: url.path
                        )
                    } else {
                        pendingAttachment = AttachmentPayload(
                            isImage: false,
                            fileExt: ext,
                            preview: nil,
                            fileURLString: url.path
                        )
                    }
                    pendingFileName = url.lastPathComponent
                }
            }
            return true
        }
    }
}
