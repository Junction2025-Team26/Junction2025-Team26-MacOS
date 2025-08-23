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
    case url(String)          // 원격 썸네일 URL (문자열로 저장)
    case base64(String)       // 썸네일 Base64 문자열
    case localPath(String)    // 로컬 파일 경로 (드롭 직후 미리보기 등)
    
    // Codable 구현은 필요시 추가(지금은 View 전용으로만 사용해도 OK)
}

struct AttachmentPayload: Hashable, Codable {
    let isImage: Bool         // true면 이미지 썸네일, false면 파일 배지
    let fileExt: String?      // "PDF" 등 (isImage=false 일 때 주로 사용)
    let preview: ImageSource? // isImage=true면 거의 필수
    let fileURLString: String?// 파일 원본 URL/경로 (옵션)
    
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
        if isImage {
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

//extension Array where Element == DashItem {
//    static let demo: [DashItem] = [
//        .init(kind: .plan,
//              title: "Don't forget your dinner.",
//              content: "You have a dinner appointment with your friend at 7 p.m. on August 24th."),
//        .init(kind: .plan,
//              title: "Design file detected.",
//              content: "Wireframe update received from the design team.",
//              attachment: .init(isImage: true, fileExt: "PNG",
//                                preview: .url("https://picsum.photos/160/120"), fileURLString: nil)),
//        .init(kind: .insight,
//              title: "A new PDF has been saved.",
//              content: "Marketing strategy document uploaded on August 23rd.",
//              attachment: .init(isImage: false, fileExt: "PDF",
//                                preview: nil, fileURLString: "https://example.com/marketing.pdf")),
//        .init(kind: .insight,
//              title: "Code snippet stored.",
//              content: "xcodeproj file dropped into your workspace.",
//              attachment: .init(isImage: false, fileExt: "XCODEPROJ", preview: nil, fileURLString: nil)),
//        .init(kind: .plan,
//              title: "User flow v2",
//              content: "Screenshot received from QA.",
//              attachment: .init(isImage: true, fileExt: "JPG",
//                                preview: .url("https://picsum.photos/161/121"), fileURLString: nil)),
//        .init(kind: .plan,
//              title: "Don't lose this idea",
//              content: "“What if we merge the onboarding and tutorial screens into one?”")
//    ]
//}
