//
//  Challenge.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

struct Challenge: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let userId: Int
    var aiInputPrompt: String?
    var aiResult: String?
    var targetDistance: Double?
    var targetTime: Int?
    var activities: [Activity]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case userId = "user_id"
        case aiInputPrompt = "ai_input_prompt"
        case aiResult = "ai_result"
        case targetDistance = "target_distance"
        case targetTime = "target_time"
        case activities
    }
}


