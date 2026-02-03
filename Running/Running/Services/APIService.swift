//
//  APIService.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class APIService {
    static let shared = APIService()
    
    // 프로덕션용
    private let baseURL = "https://running.roysoft.co.kr"
    // 테스트용: private let baseURL = "http://localhost:3031"
    private let tokenManager = TokenManager.shared
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Generic Request Method
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, NetworkError> {
        let fullURL = "\(baseURL)\(endpoint)"
        print("[APIService] 🔵 네트워크 요청 시작")
        print("[APIService] 📤 \(method.rawValue) \(fullURL)")
        print("[APIService] 📤 requiresAuth: \(requiresAuth)")
        
        guard let url = URL(string: fullURL) else {
            print("[APIService] ❌ 잘못된 URL: \(fullURL)")
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth {
            if let token = tokenManager.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                print("[APIService] ✅ Authorization 헤더 추가됨: \(token.prefix(20))...")
            } else {
                print("[APIService] ❌ Access Token이 없습니다. (requiresAuth=true)")
                return Fail(error: NetworkError.unauthorized)
                    .eraseToAnyPublisher()
            }
        }
        
        if let body = body {
            do {
                let bodyData = try JSONEncoder().encode(body)
                request.httpBody = bodyData
                if let bodyString = String(data: bodyData, encoding: .utf8) {
                    print("[APIService] 📤 Request Body: \(bodyString)")
                }
            } catch {
                print("[APIService] ❌ Body 인코딩 실패: \(error)")
                return Fail(error: NetworkError.decodingError(error))
                    .eraseToAnyPublisher()
            }
        }
        
        print("[APIService] 🔵 네트워크 요청 전송 중...")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[APIService] ❌ HTTPResponse 변환 실패")
                    throw NetworkError.unknown
                }
                
                print("[APIService] 📥 응답 받음 - Status Code: \(httpResponse.statusCode)")
                
                // Handle token expiration
                if httpResponse.statusCode == 401 {
                    print("[APIService] ⚠️ 401 Unauthorized - 토큰 만료, 토큰 갱신 시도")
                    // Try to refresh token
                    return try self.handleTokenRefresh(data: data, response: httpResponse)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                    if let errorMessage = errorMessage {
                        print("[APIService] ❌ 서버 에러 응답: \(httpResponse.statusCode) - \(errorMessage.message ?? "nil")")
                    } else {
                        print("[APIService] ❌ 서버 에러 응답: \(httpResponse.statusCode) - 응답 파싱 실패")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("[APIService] 📥 Raw 응답: \(responseString)")
                        }
                    }
                    throw NetworkError.serverError(httpResponse.statusCode, errorMessage?.message)
                }
                
                print("[APIService] ✅ 응답 성공 (200-299)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("[APIService] 📥 Response Body: \(responseString.prefix(500))...")
                }
                
                return data
            }
            .decode(type: T.self, decoder: self.jsonDecoder)
            .handleEvents(
                receiveOutput: { _ in
                    print("[APIService] ✅ 응답 디코딩 성공")
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("[APIService] ✅ 네트워크 요청 완료")
                    case .failure(let error):
                        print("[APIService] ❌ 네트워크 요청 실패: \(error)")
                        if let decodingError = error as? DecodingError {
                            self.printDecodingError(decodingError)
                        }
                    }
                }
            )
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    print("[APIService] ❌ NetworkError: \(networkError)")
                    return networkError
                } else if let decodingError = error as? DecodingError {
                    print("[APIService] ❌ DecodingError: \(decodingError)")
                    self.printDecodingError(decodingError)
                    return NetworkError.decodingError(error)
                } else {
                    print("[APIService] ❌ 기타 에러: \(error)")
                    return NetworkError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func handleTokenRefresh(data: Data, response: HTTPURLResponse) throws -> Data {
        // Try to refresh token automatically
        guard let refreshToken = tokenManager.refreshToken else {
            throw NetworkError.tokenExpired
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var refreshSuccess = false
        var error: NetworkError?
        
        let refreshDTO = TokenRefreshDTO(refreshToken: refreshToken)
        
        guard let refreshURL = URL(string: "\(baseURL)/auth/token") else {
            throw NetworkError.invalidURL
        }
        
        var refreshRequest = URLRequest(url: refreshURL)
        refreshRequest.httpMethod = "POST"
        refreshRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            refreshRequest.httpBody = try JSONEncoder().encode(refreshDTO)
        } catch {
            throw NetworkError.decodingError(error)
        }
        
        session.dataTask(with: refreshRequest) { [weak self] data, response, err in
            defer { semaphore.signal() }
            
            if let err = err {
                error = NetworkError.networkError(err)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                error = NetworkError.tokenExpired
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let refreshResponse = try decoder.decode(TokenRefreshResponseDTO.self, from: data)
                if let accessToken = refreshResponse.accessToken, let refreshToken = refreshResponse.refreshToken {
                    self?.tokenManager.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
                    refreshSuccess = true
                } else {
                    error = NetworkError.tokenExpired
                }
            } catch let decodingError {
                error = NetworkError.decodingError(decodingError)
            }
        }.resume()
        
        semaphore.wait()
        
        if let error = error {
            throw error
        }
        
        if !refreshSuccess {
            throw NetworkError.tokenExpired
        }
        
        // Retry original request with new token
        throw NetworkError.unauthorized // This will trigger retry in calling code
    }
    
    // MARK: - Date Formatter
    
    private var dateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
    
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            print("[APIService] 🔵 Date 디코딩 시도: \(dateString)")
            
            // Try ISO8601 with fractional seconds
            if let date = self.dateFormatter.date(from: dateString) {
                print("[APIService] ✅ Date 디코딩 성공 (fractional seconds): \(date)")
                return date
            }
            
            // Try ISO8601 without fractional seconds
            let formatter2 = ISO8601DateFormatter()
            formatter2.formatOptions = [.withInternetDateTime]
            if let date = formatter2.date(from: dateString) {
                print("[APIService] ✅ Date 디코딩 성공 (no fractional seconds): \(date)")
                return date
            }
            
            // Try date only (YYYY-MM-DD)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                print("[APIService] ✅ Date 디코딩 성공 (date only): \(date)")
                return date
            }
            
            print("[APIService] ❌ Date 디코딩 실패: \(dateString)")
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }
        return decoder
    }
    
    // MARK: - Decoding Error Helper
    
    private func printDecodingError(_ error: DecodingError) {
        print("[APIService] 🔍 디코딩 에러 상세 분석:")
        
        switch error {
        case .typeMismatch(let type, let context):
            print("[APIService] ❌ 타입 불일치:")
            print("[APIService]    - 기대 타입: \(type)")
            print("[APIService]    - 경로: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("[APIService]    - 설명: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                print("[APIService]    - 원인: \(underlyingError)")
            }
            
        case .valueNotFound(let type, let context):
            print("[APIService] ❌ 값 없음:")
            print("[APIService]    - 타입: \(type)")
            print("[APIService]    - 경로: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("[APIService]    - 설명: \(context.debugDescription)")
            
        case .keyNotFound(let key, let context):
            print("[APIService] ❌ 키 없음:")
            print("[APIService]    - 키: \(key.stringValue)")
            print("[APIService]    - 경로: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("[APIService]    - 설명: \(context.debugDescription)")
            
        case .dataCorrupted(let context):
            print("[APIService] ❌ 데이터 손상:")
            print("[APIService]    - 경로: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("[APIService]    - 설명: \(context.debugDescription)")
            if let underlyingError = context.underlyingError {
                print("[APIService]    - 원인: \(underlyingError)")
            }
            
        @unknown default:
            print("[APIService] ❌ 알 수 없는 디코딩 에러: \(error)")
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

struct ErrorResponse: Codable {
    let message: String?
    let error: String?
}

