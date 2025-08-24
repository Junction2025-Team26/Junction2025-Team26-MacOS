//
//  PlanModels.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import Foundation

enum ItemKind: String, Codable { case plan, insight, attachment }

// 서버/로컬 어디서 오든 썸네일 소스 3종 지원
enum ImageSource: Hashable, Codable {
    case url(String)
    case base64(String)
    case localPath(String)
    
    enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    enum SourceType: String, Codable {
        case url = "url"
        case base64 = "base64"
        case localPath = "localPath"  // 서버에서 "localPath"로 오는지 확인 필요
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(SourceType.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)
        
        switch type {
        case .url: self = .url(value)
        case .base64: self = .base64(value)
        case .localPath: self = .localPath(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .url(let str):
            try container.encode(SourceType.url, forKey: .type)
            try container.encode(str, forKey: .value)
        case .base64(let str):
            try container.encode(SourceType.base64, forKey: .type)
            try container.encode(str, forKey: .value)
        case .localPath(let str):
            try container.encode(SourceType.localPath, forKey: .type)
            try container.encode(str, forKey: .value)
        }
    }
}

struct AttachmentPayload: Hashable, Codable {
    let isImage: Bool?         // true면 이미지 썸네일, false면 파일 배지
    let fileExt: String?      // "PDF" 등 (isImage=false 일 때 주로 사용)
    let preview: ImageSource? // isImage=true면 거의 필수
    let fileURLString: String?// 파일 원본 URL/경로 (옵션)
    
    enum CodingKeys: String, CodingKey {
        case isImage = "is_image"        // snake_case로 매핑
        case fileExt = "file_ext"        // snake_case로 매핑
        case preview
        case fileURLString = "file_url_string"  // snake_case로 매핑
    }
    
    // 채팅 기능을 위한 추가 속성들
    var filename: String {
        if let urlString = fileURLString {
            // file:// 프로토콜이 포함된 URL인 경우
            if urlString.hasPrefix("file://") {
                if let url = URL(string: urlString) {
                    return url.lastPathComponent
                }
            } else {
                // 절대 경로인 경우 (예: /Users/...)
                let url = URL(fileURLWithPath: urlString)
                return url.lastPathComponent
            }
        }
        return "파일"
    }
    
    var fileExtension: String {
        return fileExt?.lowercased() ?? ""
    }
    
    var iconName: String {
        if isImage == true {
            return "photo"
        }
        
        switch fileExtension {
        case "pdf":
            return "doc.text"
        case "txt", "md":
            return "doc.plaintext"
        case "mp3", "wav", "aac":
            return "music.note"
        case "mp4", "mov", "avi":
            return "video"
        default:
            return "doc"
        }
    }
    
    var fileURL: URL? {
        guard let urlString = fileURLString else { return nil }
        return URL(string: urlString)
    }
    
    // 채팅용 초기화 메서드
    init(filename: String, fileExtension: String, iconName: String, fileURL: URL) {
        self.isImage = ["jpg", "jpeg", "png", "gif", "heic"].contains(fileExtension.lowercased())
        self.fileExt = fileExtension.uppercased()
        self.preview = .localPath(fileURL.path)
        self.fileURLString = fileURL.absoluteString
    }
    
    // 기존 초기화 메서드
    init(isImage: Bool, fileExt: String?, preview: ImageSource?, fileURLString: String?) {
        self.isImage = isImage
        self.fileExt = fileExt
        self.preview = preview
        self.fileURLString = fileURLString
    }
}


struct DashItem: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: ItemKind
    let title: String
    let content: String
    let attachment: AttachmentPayload?
    
    enum CodingKeys: String, CodingKey {
        case id, kind, title, content, attachment
    }
    
    init(id: UUID = .init(),
         kind: ItemKind,
         title: String,
         content: String,
         attachment: AttachmentPayload? = nil) {
        self.id = id
        self.kind = kind
        self.title = title
        self.content = content
        self.attachment = attachment
    }
}


// ✨ base64 전용 변환기
extension AttachmentPayload {
    func toRequestDTO() -> AttachmentPayloadRequest? {
        guard
            let fileExt = self.fileExt,
            case let .base64(base64String) = self.preview
        else {
            print("❌ base64 변환 실패 (fileExt or preview 누락)")
            return nil
        }
        
        return AttachmentPayloadRequest(
            is_image: isImage ?? false,
            file_ext: fileExt,
            preview: PreviewSourceRequest(type: "base64", value: base64String),
            file_url_string: nil // 서버엔 안 보냄
        )
    }
    
    func extractBase64Only() -> String? {
        if case let .base64(b64) = self.preview {
            return b64
        }
        return nil
    }
}

struct AttachmentPayloadRequest: Codable {
    let is_image: Bool
    let file_ext: String
    let preview: PreviewSourceRequest
    let file_url_string: String?  // 항상 null
}

struct PreviewSourceRequest: Codable {
    let type: String  // 항상 "base64"
    let value: String // base64 문자열
}
