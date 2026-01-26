//
//  Point.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

enum PointType: String, Codable {
    case earned = "earned"
    case used = "used"
}

enum ReferenceTable: String, Codable {
    case activity = "activities"
    case shop = "shop_items"
    case mission = "missions"
    case challenge = "challenges"
}

struct Point: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let title: String
    let point: Int
    let referenceTable: ReferenceTable
    let type: PointType
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt  // 백엔드가 camelCase로 응답
        case deletedAt   // 백엔드가 camelCase로 응답
        case title
        case point
        case referenceTable  // 백엔드가 camelCase로 응답
        case type
    }
}

struct UserPoint: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let pointId: Int
    let userId: Int
    let pointAmount: Int
    var referenceId: Int?
    var point: Point?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt  // 백엔드가 camelCase로 응답
        case deletedAt   // 백엔드가 camelCase로 응답
        case pointId    // 백엔드가 camelCase로 응답
        case userId     // 백엔드가 camelCase로 응답
        case pointAmount  // 백엔드가 camelCase로 응답
        case referenceId  // 백엔드가 camelCase로 응답
        case point
    }
}

