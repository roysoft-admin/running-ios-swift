//
//  ChallengeDTO.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

// 백엔드: POST /challenges - AI 챌린지 생성 요청
struct CreateChallengeDTO: Codable {
    let userUuid: String  // 백엔드: user_uuid (AI가 자동으로 생성하므로 다른 필드는 불필요)
    
    enum CodingKeys: String, CodingKey {
        case userUuid = "user_uuid"
    }
}

struct ChallengeResponseDTO: Codable {
    let challenge: Challenge
}

struct ChallengesResponseDTO: Codable {
    let challenges: [Challenge]
    let total: Int?
    let page: Int?
    let limit: Int?
}

struct UpdateChallengeDTO: Codable {
    var aiInputPrompt: String?
    var aiResult: String?
    var targetDistance: Double?
    var targetTime: Int?
    var description: String?
    
    enum CodingKeys: String, CodingKey {
        case aiInputPrompt = "ai_input_prompt"
        case aiResult = "ai_result"
        case targetDistance = "target_distance"
        case targetTime = "target_time"
        case description
    }
}

