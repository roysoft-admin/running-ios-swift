//
//  AuthService.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class AuthService {
    static let shared = AuthService()
    
    private let apiService = APIService.shared
    private let tokenManager = TokenManager.shared
    
    private init() {}
    
    // MARK: - Sign In
    
    func signIn(dto: SignInDTO) -> AnyPublisher<SignInResponseDTO, NetworkError> {
        print("[AuthService] 🔵 signIn 요청 시작")
        print("[AuthService] 📤 Endpoint: POST /auth/sign-in")
        print("[AuthService] 📤 DTO: googleToken=\(dto.googleToken ?? "nil"), appleToken=\(dto.appleToken ?? "nil"), kakaoToken=\(dto.kakaoToken ?? "nil"), naverToken=\(dto.naverToken ?? "nil")")
        
        return apiService.request(
            endpoint: "/auth/sign-in",
            method: .post,
            body: dto,
            requiresAuth: false
        )
        .handleEvents(
            receiveOutput: { [weak self] response in
                print("[AuthService] ✅ signIn 응답 받음")
                print("[AuthService] 📥 Response - accessToken 존재: \(response.accessToken != nil), refreshToken 존재: \(response.refreshToken != nil)")
                
                if let accessToken = response.accessToken, let refreshToken = response.refreshToken {
                    print("[AuthService] 🔵 토큰 저장 시작")
                    self?.tokenManager.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
                    print("[AuthService] ✅ 토큰 저장 완료")
                } else {
                    print("[AuthService] ⚠️ 토큰이 응답에 없습니다. accessToken: \(response.accessToken != nil), refreshToken: \(response.refreshToken != nil)")
                }
            },
            receiveCancel: {
                print("[AuthService] ❌ signIn 요청 취소됨")
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Sign Up
    
    func signUp(dto: SignUpDTO) -> AnyPublisher<SignUpResponseDTO, NetworkError> {
        return apiService.request(
            endpoint: "/auth/sign-up",
            method: .post,
            body: dto,
            requiresAuth: false
        )
        .handleEvents(receiveOutput: { [weak self] response in
            if let accessToken = response.accessToken, let refreshToken = response.refreshToken {
                self?.tokenManager.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
            }
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - Token Refresh
    
    func refreshToken() -> AnyPublisher<TokenRefreshResponseDTO, NetworkError> {
        guard let refreshToken = tokenManager.refreshToken else {
            return Fail(error: NetworkError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        let dto = TokenRefreshDTO(refreshToken: refreshToken)
        
        return apiService.request(
            endpoint: "/auth/token",
            method: .post,
            body: dto,
            requiresAuth: false
        )
        .handleEvents(receiveOutput: { [weak self] response in
            if let accessToken = response.accessToken, let refreshToken = response.refreshToken {
                self?.tokenManager.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
            }
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        tokenManager.clearTokens()
    }
    
    // MARK: - Verification Request
    
    func requestVerification(type: String, email: String? = nil, phone: String? = nil) -> AnyPublisher<VerificationRequestResponseDTO, NetworkError> {
        let dto = VerificationRequestDTO(type: type, email: email, phone: phone)
        
        return apiService.request(
            endpoint: "/auth/verification-request",
            method: .post,
            body: dto,
            requiresAuth: true
        )
    }
    
    // MARK: - Verify
    
    func verify(authUuid: String, code: String) -> AnyPublisher<VerifyResponseDTO, NetworkError> {
        let dto = VerifyDTO(authUuid: authUuid, code: code)
        
        return apiService.request(
            endpoint: "/auth/verify",
            method: .post,
            body: dto,
            requiresAuth: true
        )
    }
}

// 백엔드: POST /auth/token 요청
struct TokenRefreshDTO: Codable {
    let refreshToken: String  // 백엔드가 camelCase로 요청 받음
    
    enum CodingKeys: String, CodingKey {
        case refreshToken  // 백엔드가 camelCase로 요청 받음
    }
}

struct TokenRefreshResponseDTO: Codable {
    let accessToken: String?  // 백엔드: accessToken
    let refreshToken: String?  // 백엔드: refreshToken
    
    enum CodingKeys: String, CodingKey {
        case accessToken      // 백엔드가 camelCase로 응답
        case refreshToken     // 백엔드가 camelCase로 응답
    }
}

// MARK: - Verification DTOs

struct VerificationRequestDTO: Codable {
    let type: String
    let email: String?
    let phone: String?
}

struct VerificationRequestResponseDTO: Codable {
    let authUuid: String
    let code: String?  // 개발 환경에서만 반환
    
    enum CodingKeys: String, CodingKey {
        case authUuid = "auth_uuid"
        case code
    }
}

struct VerifyDTO: Codable {
    let authUuid: String
    let code: String
    
    enum CodingKeys: String, CodingKey {
        case authUuid = "auth_uuid"
        case code
    }
}

struct VerifyResponseDTO: Codable {
    let success: Bool
    let authUuid: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case authUuid = "auth_uuid"
    }
}

