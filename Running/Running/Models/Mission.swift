//
//  Mission.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

enum MissionTerm: String, Codable {
    case week = "week"
    case month = "month"
}

enum MissionType: String, Codable {
    case challengeCount = "challenge_count"
    case totalDistance = "total_distance"
}

enum UserMissionStatus: String, Codable {
    case inProgress = "진행중"
    case completed = "완료"
    case incomplete = "미완료"
}

struct Mission: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let title: String
    let point: Int
    let term: MissionTerm
    let type: MissionType
    let targetValue: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt  // 백엔드가 camelCase로 응답
        case deletedAt  // 백엔드가 camelCase로 응답
        case title
        case point
        case term
        case type
        case targetValue  // 백엔드가 camelCase로 응답
    }
}

struct UserMission: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let userId: Int
    let missionId: Int
    let status: UserMissionStatus
    let userValue: Int
    var mission: Mission?
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt  // 백엔드가 camelCase로 응답
        case deletedAt  // 백엔드가 camelCase로 응답
        case userId  // 백엔드가 camelCase로 응답
        case missionId  // 백엔드가 camelCase로 응답
        case status
        case userValue  // 백엔드가 camelCase로 응답
        case mission
        case user
    }
}


