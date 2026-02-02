//
//  ActivityPause.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

struct ActivityPause: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let activityId: Int
    let pauseStartedAt: Date
    let pauseEndedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt  // 백엔드가 camelCase로 응답
        case deletedAt   // 백엔드가 camelCase로 응답
        case activityId  // 백엔드가 camelCase로 응답
        case pauseStartedAt  // 백엔드가 camelCase로 응답
        case pauseEndedAt    // 백엔드가 camelCase로 응답
    }
    
    // Default initializer for manual creation
    init(
        id: Int,
        uuid: String,
        createdAt: Date,
        deletedAt: Date? = nil,
        activityId: Int,
        pauseStartedAt: Date,
        pauseEndedAt: Date? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.activityId = activityId
        self.pauseStartedAt = pauseStartedAt
        self.pauseEndedAt = pauseEndedAt
    }
    
    // Custom init to handle potential type mismatches from backend
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        uuid = try container.decode(String.self, forKey: .uuid)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        
        activityId = try container.decode(Int.self, forKey: .activityId)
        pauseStartedAt = try container.decode(Date.self, forKey: .pauseStartedAt)
        pauseEndedAt = try container.decodeIfPresent(Date.self, forKey: .pauseEndedAt)
    }
}
