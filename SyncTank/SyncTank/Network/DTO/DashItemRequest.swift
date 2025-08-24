//
//  DashItemRequest.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/24/25.
//

import Foundation

struct DashItemRequest: Codable {
    let id: String
    let content: String
    let attachment: AttachmentRequest?
    
    enum CodingKeys: String, CodingKey {
        case id, content, attachment
    }
}

struct AttachmentRequest: Codable {
    let isImage: Bool
    let fileExt: String
    let preview: PreviewRequest
    let fileUrlString: String
    
    enum CodingKeys: String, CodingKey {
        case isImage = "is_image"
        case fileExt = "file_ext"
        case preview, fileUrlString = "file_url_string"
    }
}

struct PreviewRequest: Codable {
    let type: String
    let value: String
}
