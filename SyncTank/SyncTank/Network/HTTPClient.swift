//
//  HTTPClient.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/24/25.
//

import Foundation

enum ReqeustError: Error {
    case invalidURL
    case responseError
    case decodingError
}

protocol HTTPClient {
    func request<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async -> Result<T, ReqeustError>
}

extension HTTPClient {
    func request<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async -> Result<T, ReqeustError> {
        let urlString = "http://\(endpoint.host)\(endpoint.path)"
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header
        
        if let body = endpoint.body {
            // JSONEncoder 사용 (Codable 객체 지원)
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            
            if let jsonData = try? encoder.encode(body),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("�� [REQUEST BODY]\n\(jsonString)")
            }
            
            request.httpBody = try? encoder.encode(body)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidURL)
            }
            
            // 응답 상태 코드와 데이터 로깅
            print("📋 HTTP Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📋 Response Data: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                // 성공 응답
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase  // 이 줄 추가!
                    let decoded = try decoder.decode(T.self, from: data)
                    return .success(decoded)
                } catch {
                    print("❌ Decoding Error: \(error)")
                    return .failure(.decodingError)
                }
                
            case 400:
                print("❌ Bad Request (400)")
                return .failure(.responseError)
                
            case 422:
                print("❌ Validation Error (422)")
                return .failure(.responseError)
                
            case 500:
                print("❌ Server Error (500)")
                return .failure(.responseError)
                
            default:
                print("❌ Unexpected Status: \(httpResponse.statusCode)")
                return .failure(.responseError)
            }
            
        } catch {
            print("❌ Network Error: \(error)")
            return .failure(.decodingError)
        }
    }
}
