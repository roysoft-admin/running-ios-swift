//
//  MissionDTO.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

// 백엔드: PUT /user-missions/:id 응답
struct UserMissionResponseDTO: Codable {
    let userMission: UserMission  // 백엔드: user-mission (kebab-case)
    
    enum CodingKeys: String, CodingKey {
        case userMission = "user-mission"  // 백엔드가 kebab-case로 응답
    }
}

// 백엔드: GET /user-missions 응답
struct UserMissionsListResponseDTO: Codable {
    let userMissions: [UserMission]  // 백엔드: user_missions (snake_case)
    
    enum CodingKeys: String, CodingKey {
        case userMissions = "user_missions"  // 백엔드가 snake_case로 응답
    }
}

struct MissionResponseDTO: Codable {
    let mission: Mission
}

struct MissionsListResponseDTO: Codable {
    let missions: [Mission]
    let total: Int?
    let page: Int?
    let limit: Int?
}

struct UpdateUserMissionDTO: Codable {
    var status: UserMissionStatus?
    var userValue: Int?
    
    enum CodingKeys: String, CodingKey {
        case status
        case userValue = "user_value"
    }
}

