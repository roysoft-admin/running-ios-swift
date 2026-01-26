//
//  SignUpDTO.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

struct SignUpDTO: Codable {
    var googleToken: String?
    var appleToken: String?
    var kakaoToken: String?
    var naverToken: String?
    var name: String?
    var birthday: String? // YYYY-MM-DD format
    var gender: User.Gender?
    
    enum CodingKeys: String, CodingKey {
        case googleToken = "google_token"
        case appleToken = "apple_token"
        case kakaoToken = "kakao_token"
        case naverToken = "naver_token"
        case name
        case birthday
        case gender
    }
}

struct SignUpResponseDTO: Codable {
    let user: User
    let accessToken: String?  // 백엔드: accessToken
    let refreshToken: String?  // 백엔드: refreshToken
    
    enum CodingKeys: String, CodingKey {
        case user
        case accessToken      // 백엔드가 camelCase로 응답
        case refreshToken     // 백엔드가 camelCase로 응답
    }
}

struct SignInDTO: Codable {
    var googleToken: String?
    var appleToken: String?
    var kakaoToken: String?
    var naverToken: String?
    
    enum CodingKeys: String, CodingKey {
        case googleToken = "google_token"
        case appleToken = "apple_token"
        case kakaoToken = "kakao_token"
        case naverToken = "naver_token"
    }
}

struct SignInResponseDTO: Codable {
    let user: User
    let accessToken: String?  // 백엔드: accessToken
    let refreshToken: String?  // 백엔드: refreshToken
    let isNewUser: Bool?      // 백엔드: isNewUser
    
    enum CodingKeys: String, CodingKey {
        case user
        case accessToken      // 백엔드가 camelCase로 응답
        case refreshToken     // 백엔드가 camelCase로 응답
        case isNewUser        // 백엔드가 camelCase로 응답
    }
}

