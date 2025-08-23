//
//  PopoverCapsuleInputView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI
import UniformTypeIdentifiers

/// 전역 팝오버에서 쓰는 래퍼: 내부 상태 관리 → (text, attachment) 콜백만 밖으로
struct PopoverCapsuleInputView: View {
    var onSend: (_ text: String, _ attachment: AttachmentPayload?) -> Void
    var onRejectMultiple: () -> Void = {}

    @State private var text: String = ""
    @State private var pendingAttachment: AttachmentPayload? = nil
    @State private var pendingFileName: String? = nil
    @State private var isTargeted = false
    @State private var isTextFieldFocused: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                if let att = pendingAttachment {
                    ComposerAttachmentChip(attachment: att, fileName: pendingFileName) {
                        pendingAttachment = nil
                        pendingFileName = nil
                    }
                }
                
                // 직접 TextField 구현 - Clipgo 패턴
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Drop, Ask anything", text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16, weight: .light))
                        .id("popoverTextField") // 고유 ID 추가
                        .onSubmit {
                            handleSend()
                        }
                        .onTapGesture {
                            isTextFieldFocused = true
                            print("TextField tapped, focus: \(isTextFieldFocused)")
                            
                            // 강제로 포커스 설정
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let window = NSApp.keyWindow {
                                    window.makeFirstResponder(nil)
                                }
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .padding(.leading, 16)
            
            Button(action: handleSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
        }
        .padding(.vertical, 12)
        .frame(width: 372, height: 112)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color("CapsuleColor"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .stroke(Color.white, lineWidth: 1)
        )
        .onAppear { 
            print("PopoverCapsuleInputView appeared")
            
            // Clipgo 패턴: onAppear에서 포커스 설정
            DispatchQueue.main.async {
                isTextFieldFocused = true
                print("Focus set in onAppear: \(isTextFieldFocused)")
            }
            
            // 추가 포커스 시도
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTextFieldFocused = true
                print("Focus attempt 1: \(isTextFieldFocused)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
                print("Focus attempt 2: \(isTextFieldFocused)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isTextFieldFocused = true
                print("Focus attempt 3: \(isTextFieldFocused)")
            }
        }
        .onChange(of: isTextFieldFocused) { newValue in
            print("TextField focus changed to: \(newValue)")
        }
        .onDrop(of: [UTType.fileURL, UTType.image, UTType.data], isTargeted: $isTargeted) { providers in
            handleFileDrop(providers: providers)
            return true
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)
    }
    
    private func handleSend() {
        onSend(text, pendingAttachment)
        text = ""
        pendingAttachment = nil
        pendingFileName = nil
    }
    
    private func handleFileDrop(providers: [NSItemProvider]) {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
                if let data = data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        urls.append(url)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                // 첫 번째 파일만 처리 (여러 파일 드롭 시 첫 번째만)
                let url = urls[0]
                processDroppedFile(url: url)
            }
        }
    }
    
    private func processDroppedFile(url: URL) {
        let fileExtension = url.pathExtension.uppercased()
        let isImage = ["JPG", "JPEG", "PNG", "GIF", "BMP", "TIFF", "HEIC", "WEBP"].contains(fileExtension)
        
        let attachment = AttachmentPayload(
            isImage: isImage,
            fileExt: fileExtension,
            preview: isImage ? .localPath(url.path) : nil,
            fileURLString: url.absoluteString
        )
        
        pendingAttachment = attachment
        pendingFileName = url.lastPathComponent
        
        // 이미지인 경우 썸네일 생성 로직은 별도로 구현 필요
        if isImage {
            // TODO: 이미지 썸네일 생성 및 미리보기
            print("Image dropped: \(url.lastPathComponent)")
        } else {
            print("File dropped: \(url.lastPathComponent)")
        }
    }
}
