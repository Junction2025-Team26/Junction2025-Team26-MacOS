//
//  EndPoint.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/24/25.
//

import Foundation

protocol Endpoint {
    var host: String { get }
    var path: String { get }
    var method: RequestMethod { get }
    var header: [String: String]? { get }
    var body: Encodable? { get }
}

enum SyncTankEndPoint {
    case saveDocument(
        id: String,
        kind: String,
        title: String,
        content: String,
        leftTime: String?,
        attachment: AttachmentRequest?,
        isUpdated: Bool
    )
    
    case fetchDocuments
}


extension SyncTankEndPoint: Endpoint {
    var host: String { return "3.39.148.133:8000" }
    
    var path: String {
        switch self {
        case .saveDocument: return "/savedocs"
        case .fetchDocuments: return "/fetchdocs"
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .saveDocument: return .post
        case .fetchDocuments: return .get//
        }
    }
    
    var header: [String: String]? {
        return [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]
    }
    
    var body: Encodable? {
        switch self {
        case .saveDocument(
            let id,
            let kind,
            let title,
            let content,
            let leftTime,
            let attachment,
            let isUpdated):
            return DashItemRequest (
                id: id,
                content: content,
                attachment: attachment,
            )
        case .fetchDocuments:
            return nil
        }
    }
}
    // Encodable → Dictionary 변환 확장
    extension Encodable {
        func asDictionary() -> [String: Any]? {
            guard let data = try? JSONEncoder().encode(self) else { return nil }
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
    }
