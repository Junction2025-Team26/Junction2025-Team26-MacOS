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
    @FocusState private var isTextFieldFocusedState: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                if let att = pendingAttachment {
                    ComposerAttachmentChip(attachment: att, fileName: pendingFileName) {
                        print("🗑️ 첨부파일 제거됨")
                        pendingAttachment = nil
                        pendingFileName = nil
                    }
                }
                
                HStack {
                    TextField("Drop, Ask anything", text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16, weight: .light))
                        .id("popoverTextField") // 고유 ID 추가
                        .focused($isTextFieldFocusedState)
                        .onSubmit {
                            handleSend()
                        }
                        .onTapGesture {
                            isTextFieldFocused = true
                            print("TextField tapped, focus: \(isTextFieldFocused)")
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
            
            // 즉시 포커스 설정
            DispatchQueue.main.async {
                isTextFieldFocusedState = true
                print("Focus set in onAppear: \(isTextFieldFocusedState)")
            }
            
            // 추가 포커스 시도 (SwiftUI 포커스 시스템이 준비될 때까지)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocusedState = true
                print("Focus attempt 1: \(isTextFieldFocusedState)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocusedState = true
                print("Focus attempt 2: \(isTextFieldFocusedState)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isTextFieldFocusedState = true
                print("Focus attempt 3: \(isTextFieldFocusedState)")
            }
        }
        .onChange(of: isTextFieldFocused) { newValue in
            print("TextField focus changed to: \(newValue)")
        }
        .onChange(of: pendingAttachment) { newValue in
            print("🔄 pendingAttachment 변경됨: \(newValue != nil ? "설정됨" : "nil")")
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
        print("🔄 handleFileDrop 시작 - providers: \(providers.count)개")
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for (index, provider) in providers.enumerated() {
            group.enter()
            print("📁 Provider \(index) 처리 중...")
            
            // 사용 가능한 타입 식별자들 확인
            let availableTypes = provider.registeredTypeIdentifiers
            print("📋 Provider \(index) 사용 가능한 타입들: \(availableTypes)")
            
            // 여러 타입을 시도해보기
            self.tryLoadFileFromProvider(provider, index: index) { url in
                if let url = url {
                    DispatchQueue.main.async {
                        urls.append(url)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("📋 모든 providers 처리 완료 - URLs: \(urls)")
            if !urls.isEmpty {
                // 첫 번째 파일만 처리 (여러 파일 드롭 시 첫 번째만)
                let url = urls[0]
                print("🎯 첫 번째 파일 처리: \(url)")
                self.processDroppedFile(url: url)
            } else {
                print("❌ 처리할 URL이 없음")
            }
        }
    }
    
    private func tryLoadFileFromProvider(_ provider: NSItemProvider, index: Int, completion: @escaping (URL?) -> Void) {
        print("🔍 Provider \(index)에서 지원하는 타입들: \(provider.registeredTypeIdentifiers)")
        
        // 지원하는 타입 중 첫 번째 것을 사용
        guard let supportedType = provider.registeredTypeIdentifiers.first else {
            print("❌ Provider \(index)에서 지원하는 타입이 없음")
            completion(nil)
            return
        }
        
        print("✅ Provider \(index)에서 \(supportedType) 타입 사용")
        
        // 모든 타입을 동일하게 처리 (데이터를 임시 파일로 저장)
        provider.loadDataRepresentation(forTypeIdentifier: supportedType) { data, error in
            if let error = error {
                print("❌ Provider \(index) \(supportedType) 로드 실패: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("❌ Provider \(index) \(supportedType) 데이터 없음")
                completion(nil)
                return
            }
            
            // 임시 파일로 저장
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "dropped_file_\(Date().timeIntervalSince1970).\(supportedType.replacingOccurrences(of: ".", with: "_"))"
            let tempURL = tempDir.appendingPathComponent(fileName)
            
            do {
                try data.write(to: tempURL)
                print("✅ Provider \(index) \(supportedType) 임시 파일 생성 성공: \(tempURL)")
                completion(tempURL)
            } catch {
                print("❌ Provider \(index) \(supportedType) 임시 파일 생성 실패: \(error)")
                completion(nil)
            }
        }
    }
    

    

    
    private func processDroppedFile(url: URL) {
        print("🔄 processDroppedFile 시작: \(url)")
        
        // 실제 파일 확장자 추출 (타입 식별자가 아닌)
        let actualFileExtension = getActualFileExtension(from: url)
        let isImage = ["JPG", "JPEG", "PNG", "GIF", "BMP", "TIFF", "HEIC", "WEBP"].contains(actualFileExtension)
        
        // 파일 경로를 절대 경로로 설정 (file:// 프로토콜 제거)
        let filePath = url.path
        
        print("📁 Actual file extension: \(actualFileExtension)")
        print("🖼️ Is image: \(isImage)")
        print("📂 File path: \(filePath)")
        print("📄 File name: \(url.lastPathComponent)")
        
        let attachment = AttachmentPayload(
            isImage: isImage,
            fileExt: actualFileExtension,
            preview: isImage ? .localPath(filePath) : nil,
            fileURLString: filePath  // 절대 경로 사용
        )
        
        print("📎 Attachment 생성됨:")
        print("   - isImage: \(attachment.isImage)")
        print("   - fileExt: \(attachment.fileExt ?? "nil")")
        print("   - preview: \(attachment.preview != nil ? "있음" : "없음")")
        print("   - fileURLString: \(attachment.fileURLString ?? "nil")")
        print("   - filename: \(attachment.filename)")
        
        // 상태 업데이트
        pendingAttachment = attachment
        pendingFileName = url.lastPathComponent
        
        print("✅ 상태 업데이트 완료:")
        print("   - pendingAttachment: \(pendingAttachment != nil ? "설정됨" : "nil")")
        print("   - pendingFileName: \(pendingFileName ?? "nil")")
        
        // 이미지인 경우 썸네일 생성 로직은 별도로 구현 필요
        if isImage {
            print("🖼️ Image preview path: \(filePath)")
        }
    }
    
    private func getActualFileExtension(from url: URL) -> String {
        let fileName = url.lastPathComponent
        
        // 타입 식별자 기반 파일명에서 실제 확장자 추출
        if fileName.contains("public_png") || fileName.contains("public.png") {
            return "PNG"
        } else if fileName.contains("public_jpeg") || fileName.contains("public.jpg") || fileName.contains("public.jpeg") {
            return "JPG"
        } else if fileName.contains("public_gif") || fileName.contains("public.gif") {
            return "GIF"
        } else if fileName.contains("public_bmp") || fileName.contains("public.bmp") {
            return "BMP"
        } else if fileName.contains("public_tiff") || fileName.contains("public.tiff") {
            return "TIFF"
        } else if fileName.contains("public_heic") || fileName.contains("public.heic") {
            return "HEIC"
        } else if fileName.contains("public_webp") || fileName.contains("public.webp") {
            return "WEBP"
        } else if fileName.contains("com_apple_quicktime-movie") || fileName.contains("com.apple.quicktime-movie") {
            return "MOV"
        } else if fileName.contains("com_compuserve_gif") || fileName.contains("com.compuserve.gif") {
            return "GIF"
        } else if fileName.contains("com_apple_disk-image-udif") || fileName.contains("com.apple.disk-image-udif") {
            return "DMG"
        } else if fileName.contains("com_apple_zip-archive") || fileName.contains("com.apple.zip-archive") {
            return "ZIP"
        } else if fileName.contains("com_adobe_pdf") || fileName.contains("com.adobe.pdf") {
            return "PDF"
        }
        
        // 기본값: 파일명에서 확장자 추출 시도
        return url.pathExtension.uppercased()
    }
}
