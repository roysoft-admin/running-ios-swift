//
//  ActivityDTO.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

// 백엔드: POST /activities - 러닝 시작 시 호출
struct CreateActivityDTO: Codable {
    let userUuid: String      // 백엔드: user_uuid
    var challengeUuid: String? // 백엔드: challenge_uuid (optional)
    let startTime: String // 백엔드: start_time (ISO 8601 문자열)
    
    enum CodingKeys: String, CodingKey {
        case userUuid = "user_uuid"
        case challengeUuid = "challenge_uuid"
        case startTime = "start_time"
    }
}

// 백엔드: POST /activity-routes - 러닝 중 2초마다 호출
struct CreateActivityRouteDTO: Codable {
    let createdAt: String  // 백엔드: created_at (ISO 8601 문자열)
    let activityUuid: String     // 백엔드: activity_uuid
    let lat: Double         // 백엔드: lat
    let long: Double        // 백엔드: long
    var speed: Double?      // 백엔드: speed (optional)
    var altitude: Double?  // 백엔드: altitude (optional)
    let seq: Int           // 백엔드: seq
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case activityUuid = "activity_uuid"
        case lat
        case long
        case speed
        case altitude
        case seq
    }
}

struct ActivityResponseDTO: Codable {
    let activity: Activity
}

// 백엔드: GET /activities 응답
struct ActivitiesListResponseDTO: Codable {
    let activities: [Activity]
    let totalCount: Int  // 백엔드: total_count
    
    enum CodingKeys: String, CodingKey {
        case activities
        case totalCount = "total_count"
    }
}

// 백엔드: PUT /activities/:id - 러닝 종료 시 호출
struct UpdateActivityDTO: Codable {
    var distance: Double?      // 백엔드: distance (optional)
    var endTime: String?       // 백엔드: end_time (ISO 8601 문자열, optional)
    var averageSpeed: Double?  // 백엔드: average_speed (optional)
    var calories: Int?         // 백엔드: calories (optional)
    
    enum CodingKeys: String, CodingKey {
        case distance
        case endTime = "end_time"
        case averageSpeed = "average_speed"
        case calories
    }
}

