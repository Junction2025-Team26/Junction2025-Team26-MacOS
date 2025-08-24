//
//  SyncTankService.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/24/25.
//

import Foundation

final class SyncTankService: SyncTankServicable, HTTPClient {
    
    func saveDocument(
        id: String,
        kind: String,
        title: String,
        content: String,
        leftTime: String?,
        attachment: AttachmentPayload?,
        isUpdated: Bool
    ) async -> Result<String, ReqeustError> {
        
        // AttachmentPayload를 AttachmentRequest로 변환
        let attachmentRequest: AttachmentRequest?
        if let attachment = attachment {
            let previewType: String
            let previewValue: String
            
            if let preview = attachment.preview {
                switch preview {
                case .base64(let base64String):
                    previewType = "base64"
                    previewValue = base64String
                case .localPath(let path):
                    // 로컬 파일을 base64로 변환
                    if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                        previewType = "base64"
                        previewValue = data.base64EncodedString()
                    } else {
                        return .failure(.responseError)
                    }
                case .url(let urlString):
                    // URL에서 데이터를 가져와서 base64로 변환
                    if let url = URL(string: urlString),
                       let data = try? Data(contentsOf: url) {
                        previewType = "base64"
                        previewValue = data.base64EncodedString()
                    } else {
                        return .failure(.responseError)
                    }
                }
            } else {
                return .failure(.responseError)
            }
            
            attachmentRequest = AttachmentRequest(
                isImage: attachment.isImage ?? false,
                fileExt: attachment.fileExt ?? "",
                preview: PreviewRequest(type: previewType, value: previewValue),
                fileUrlString: attachment.fileURLString ?? ""
            )
        } else {
            attachmentRequest = nil
        }
        
        // DashItemRequest 생성
        let dashItemRequest = DashItemRequest(
            id: id,
            content: content,
            attachment: attachmentRequest ?? AttachmentRequest(
                isImage: false,
                fileExt: "",
                preview: PreviewRequest(type: "base64", value: ""),
                fileUrlString: ""
            )
        )
        
        let endpoint = SyncTankEndPoint.saveDocument(
            id: id,
            kind: kind,
            title: title,
            content: content,
            leftTime: leftTime,
            attachment: attachmentRequest, // DashItemRequest 전달
            isUpdated: isUpdated
        )
        // String 대신 SaveDocumentResponse 모델 사용
        let result = await request(endpoint: endpoint, responseModel: SaveDocumentResponse.self)
        
        switch result {
        case .success(let response):
            return .success(response.ok ? "Success" : "Failed")
        case .failure(let error):
            return .failure(error)
        }
    }
    func fetchDocuments() async -> Result<[DashItem], ReqeustError> {
        let endpoint = SyncTankEndPoint.fetchDocuments
        return await request(endpoint: endpoint, responseModel: [DashItem].self)
    }
}
