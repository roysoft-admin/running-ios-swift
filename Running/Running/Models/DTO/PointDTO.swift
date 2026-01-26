//
//  PointDTO.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

// 백엔드: POST /points/user-points - 포인트 적립/사용
struct CreateUserPointDTO: Codable {
    let userUuid: String        // 백엔드: user_uuid
    let pointUuid: String       // 백엔드: point_uuid
    let point: Int         // 백엔드: point (적립: 양수, 사용: 음수)
    var referenceUuid: String? // 백엔드: reference_uuid (optional)
    
    enum CodingKeys: String, CodingKey {
        case userUuid = "user_uuid"
        case pointUuid = "point_uuid"
        case point
        case referenceUuid = "reference_uuid"
    }
}

// 백엔드: POST /points/user-points 응답
struct UserPointResponseDTO: Codable {
    let userPoint: UserPoint  // 백엔드: user_point (snake_case)
    
    enum CodingKeys: String, CodingKey {
        case userPoint = "user_point"  // 백엔드가 snake_case로 응답
    }
}

// 백엔드: GET /points/user-points 응답
struct UserPointsListResponseDTO: Codable {
    let userPoints: [UserPoint]  // 백엔드: user-points (kebab-case)
    let totalCount: Int?         // 백엔드: total_count (snake_case)
    
    enum CodingKeys: String, CodingKey {
        case userPoints = "user-points"  // 백엔드가 kebab-case로 응답
        case totalCount = "total_count"   // 백엔드가 snake_case로 응답
    }
}

struct PointResponseDTO: Codable {
    let point: Point
}

struct PointsListResponseDTO: Codable {
    let points: [Point]
    let totalCount: Int?  // 백엔드: total_count (snake_case)
    
    enum CodingKeys: String, CodingKey {
        case points
        case totalCount = "total_count"  // 백엔드가 snake_case로 응답
    }
}

