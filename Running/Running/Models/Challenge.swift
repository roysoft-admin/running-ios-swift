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
    var description: String?
    var activities: [Activity]?
    
    // 커스텀 디코딩: targetDistance가 String 또는 Double로 올 수 있음
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        uuid = try container.decode(String.self, forKey: .uuid)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        userId = try container.decode(Int.self, forKey: .userId)
        aiInputPrompt = try container.decodeIfPresent(String.self, forKey: .aiInputPrompt)
        aiResult = try container.decodeIfPresent(String.self, forKey: .aiResult)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        activities = try container.decodeIfPresent([Activity].self, forKey: .activities)
        
        // targetDistance: String 또는 Double로 올 수 있음
        if let targetDistanceString = try? container.decodeIfPresent(String.self, forKey: .targetDistance),
           let value = Double(targetDistanceString) {
            targetDistance = value
        } else {
            targetDistance = try container.decodeIfPresent(Double.self, forKey: .targetDistance)
        }
        
        // targetTime: String 또는 Int로 올 수 있음
        if let targetTimeString = try? container.decodeIfPresent(String.self, forKey: .targetTime),
           let value = Int(targetTimeString) {
            targetTime = value
        } else {
            targetTime = try container.decodeIfPresent(Int.self, forKey: .targetTime)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt  // 백엔드가 camelCase로 응답
        case deletedAt  // 백엔드가 camelCase로 응답
        case userId  // 백엔드가 camelCase로 응답
        case aiInputPrompt = "ai_input_prompt"
        case aiResult = "ai_result"
        case targetDistance  // 백엔드가 camelCase로 응답
        case targetTime  // 백엔드가 camelCase로 응답
        case description
        case activities
    }
}


