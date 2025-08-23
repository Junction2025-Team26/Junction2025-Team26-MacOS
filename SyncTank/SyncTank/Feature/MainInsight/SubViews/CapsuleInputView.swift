//
//  CapsuleInputView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//
import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct CapsuleInputView: View {
    @Binding var text: String
    @Binding var pendingAttachment: AttachmentPayload?
    @Binding var pendingFileName: String?
    
    var onSend: () -> Void = { }
    var onRejectMultiple: () -> Void = { }
    
    @State private var isDropTargeted = false
    @State private var keyboardManager: KeyboardManager?
    
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
        .frame(width: Metrics.capsuleWidth, height: Metrics.capsuleHeight)
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
        .onAppear {
            // 전역 Command+V 노티피케이션 수신 시작
            startGlobalCommandVListening()
        }
        .onDisappear {
            // 전역 Command+V 노티피케이션 수신 중지
            stopGlobalCommandVListening()
        }
    }
    
    private func startGlobalCommandVListening() {
        print("📡 메인뷰 전역 Command+V 노티피케이션 수신 시작")
        
        // 전역 Command+V 노티피케이션 수신
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MainWindowCommandVPaste"),
            object: nil,
            queue: .main
        ) { _ in
            print("🎯 메인뷰에서 전역 Command+V 노티피케이션 수신됨")
            self.handleCommandVPaste()
        }
    }
    
    private func stopGlobalCommandVListening() {
        print("📡 메인뷰 전역 Command+V 노티피케이션 수신 중지")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("MainWindowCommandVPaste"), object: nil)
    }
    
    private func startKeyboardMonitoring() {
        // 이미 모니터링 중이면 중복 등록 방지
        if keyboardManager != nil {
            print("⌨️ 메인뷰 이미 키보드 모니터링 중입니다")
            return
        }
        
        print("⌨️ 메인뷰 키보드 모니터링 시작")
        
        // KeyboardManager 인스턴스 생성
        keyboardManager = KeyboardManager()
        keyboardManager?.startMonitoring {
            print("🎯 메인뷰 Command+V 감지됨!")
            DispatchQueue.main.async {
                self.handleCommandVPaste()
            }
        }
    }
    
    private func stopKeyboardMonitoring() {
        keyboardManager?.stopMonitoring()
        keyboardManager = nil
        print("⌨️ 메인뷰 키보드 모니터링 중지")
    }
    
    private func handleCommandVPaste() {
        print("📋 메인뷰 Command+V 붙여넣기 처리 시작")
        
        // 클립보드에서 직접 이미지 가져오기 (여러 방법 시도)
        var clipboardImage: NSImage?
        
        // 방법 1: NSImage로 직접 읽기
        if let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            clipboardImage = image
            print("✅ 메인뷰 클립보드에서 NSImage 직접 읽기 성공: \(image.size)")
        }
        
        // 방법 2: 이미지 데이터로 읽기
        if clipboardImage == nil {
            let imageTypes = [UTType.png.identifier, UTType.jpeg.identifier, UTType.tiff.identifier, UTType.image.identifier]
            for type in imageTypes {
                if let data = NSPasteboard.general.data(forType: NSPasteboard.PasteboardType(type)) {
                    if let image = NSImage(data: data) {
                        clipboardImage = image
                        print("✅ 메인뷰 클립보드에서 \(type) 데이터로 이미지 읽기 성공: \(image.size)")
                        break
                    }
                }
            }
        }
        
        // 방법 3: TIFF 데이터로 읽기
        if clipboardImage == nil {
            if let tiffData = NSPasteboard.general.data(forType: .tiff) {
                if let image = NSImage(data: tiffData) {
                    clipboardImage = image
                    print("✅ 메인뷰 클립보드에서 TIFF 데이터로 이미지 읽기 성공: \(image.size)")
                }
            }
        }
        
        if let image = clipboardImage {
            processClipboardImage(image)
        } else {
            print("ℹ️ 메인뷰 클립보드에 이미지가 없음")
            print("🔍 메인뷰 클립보드 내용 확인:")
            let types = NSPasteboard.general.types
            print("📋 메인뷰 클립보드 타입들: \(types)")
            
            // 텍스트가 있는지도 확인
            if let text = NSPasteboard.general.string(forType: .string) {
                print("📝 메인뷰 클립보드 텍스트: \(text)")
            }
        }
    }
    
    private func processClipboardImage(_ image: NSImage) {
        print("🖼️ 메인뷰 클립보드 이미지 처리 시작")
        print("📊 입력 이미지 크기: \(image.size)")
        
        // 이미지를 임시 파일로 저장
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "main_pasted_image_\(Date().timeIntervalSince1970).png"
        let tempURL = tempDir.appendingPathComponent(fileName)
        print("📁 메인뷰 임시 파일 경로: \(tempURL)")
        
        // PNG 데이터로 변환
        print("🔄 메인뷰 TIFF 데이터 추출 시도")
        if let tiffData = image.tiffRepresentation {
            print("✅ 메인뷰 TIFF 데이터 추출 성공: \(tiffData.count) bytes")
            
            print("🔄 메인뷰 NSBitmapImageRep 생성 시도")
            if let bitmapImage = NSBitmapImageRep(data: tiffData) {
                print("✅ 메인뷰 NSBitmapImageRep 생성 성공")
                
                print("🔄 메인뷰 PNG 데이터 변환 시도")
                if let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    print("✅ 메인뷰 PNG 데이터 변환 성공: \(pngData.count) bytes")
                    
                    do {
                        try pngData.write(to: tempURL)
                        print("✅ 메인뷰 붙여넣기 이미지 임시 파일 생성: \(tempURL)")
                        
                        // 첨부파일로 설정
                        let attachment = AttachmentPayload(
                            isImage: true,
                            fileExt: "PNG",
                            preview: .localPath(tempURL.path),
                            fileURLString: tempURL.path
                        )
                        
                        pendingAttachment = attachment
                        pendingFileName = fileName
                        
                        print("✅ 메인뷰 붙여넣기 이미지가 첨부파일로 설정됨")
                        print("📊 메인뷰 pendingAttachment: \(pendingAttachment != nil ? "설정됨" : "nil")")
                        print("📊 메인뷰 pendingFileName: \(pendingFileName ?? "nil")")
                        
                    } catch {
                        print("❌ 메인뷰 붙여넣기 이미지 저장 실패: \(error)")
                    }
                } else {
                    print("❌ 메인뷰 PNG 데이터 변환 실패")
                }
            } else {
                print("❌ 메인뷰 NSBitmapImageRep 생성 실패")
            }
        } else {
            print("❌ 메인뷰 TIFF 데이터 추출 실패")
        }
    }
}
