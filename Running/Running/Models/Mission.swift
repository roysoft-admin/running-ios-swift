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
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case title
        case point
        case term
        case type
        case targetValue = "target_value"
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case userId = "user_id"
        case missionId = "mission_id"
        case status
        case userValue = "user_value"
        case mission
    }
}


