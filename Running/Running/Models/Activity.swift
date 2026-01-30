//
//  Activity.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

enum ChallengeStatus: String, Codable {
    case inProgress = "진행중"
    case success = "성공"
    case failed = "실패"
}

struct Activity: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let userId: Int
    let distance: Double
    var calories: Int?
    var challengeId: Int?
    var pointId: Int?
    let startTime: Date
    let endTime: Date? // 종료되지 않은 activity는 nil
    var averageSpeed: Double?
    var challengeStatus: ChallengeStatus?
    var routes: [ActivityRoute]?
    var challenge: Challenge? // 챌린지 정보 (백엔드에서 leftJoinAndSelect로 함께 조회)
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt  // 백엔드가 camelCase로 응답
        case deletedAt   // 백엔드가 camelCase로 응답
        case userId     // 백엔드가 camelCase로 응답
        case distance
        case calories
        case challengeId  // 백엔드가 camelCase로 응답
        case pointId     // 백엔드가 camelCase로 응답
        case startTime   // 백엔드가 camelCase로 응답
        case endTime     // 백엔드가 camelCase로 응답
        case averageSpeed  // 백엔드가 camelCase로 응답
        case challengeStatus  // 백엔드가 camelCase로 응답
        case routes
        case challenge
    }
    
    // Default initializer for manual creation
    init(
        id: Int,
        uuid: String,
        createdAt: Date,
        deletedAt: Date? = nil,
        userId: Int,
        distance: Double,
        calories: Int? = nil,
        challengeId: Int? = nil,
        pointId: Int? = nil,
        startTime: Date,
        endTime: Date? = nil,
        averageSpeed: Double? = nil,
        challengeStatus: ChallengeStatus? = nil,
        routes: [ActivityRoute]? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.userId = userId
        self.distance = distance
        self.calories = calories
        self.challengeId = challengeId
        self.pointId = pointId
        self.startTime = startTime
        self.endTime = endTime
        self.averageSpeed = averageSpeed
        self.challengeStatus = challengeStatus
        self.routes = routes
    }
    
    // Custom init to handle potential type mismatches from backend
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        uuid = try container.decode(String.self, forKey: .uuid)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        
        userId = try container.decode(Int.self, forKey: .userId)
        
        // Handle distance as String or Double
        if let distanceString = try? container.decode(String.self, forKey: .distance) {
            distance = Double(distanceString) ?? 0.0
        } else {
            distance = try container.decode(Double.self, forKey: .distance)
        }
        
        calories = try container.decodeIfPresent(Int.self, forKey: .calories)
        challengeId = try container.decodeIfPresent(Int.self, forKey: .challengeId)
        pointId = try container.decodeIfPresent(Int.self, forKey: .pointId)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime) // 종료되지 않은 activity는 nil
        
        // Handle averageSpeed as String or Double
        if let averageSpeedString = try? container.decode(String.self, forKey: .averageSpeed) {
            averageSpeed = Double(averageSpeedString)
        } else {
            averageSpeed = try container.decodeIfPresent(Double.self, forKey: .averageSpeed)
        }
        
        challengeStatus = try container.decodeIfPresent(ChallengeStatus.self, forKey: .challengeStatus)
        routes = try container.decodeIfPresent([ActivityRoute].self, forKey: .routes)
        challenge = try container.decodeIfPresent(Challenge.self, forKey: .challenge)
    }
    
    // Computed properties for UI
    var time: TimeInterval {
        guard let endTime = endTime else {
            // 종료되지 않은 activity는 현재 시간 기준으로 계산
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    var pace: Double {
        guard distance > 0 else { return 0 }
        return (time / 60) / distance
    }
    
    var points: Int {
        // TODO: Get from point relation if needed
        return 0
    }
    
    var type: RunningType {
        return challengeId != nil ? .aiChallenge : .normal
    }
    
    enum RunningType: String {
        case normal = "일반"
        case aiChallenge = "AI 챌린지"
    }
}

struct ActivityRoute: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let activityId: Int
    let lat: Double
    let long: Double
    var speed: Double?
    var altitude: Double?
    let seq: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt  // 백엔드가 camelCase로 응답
        case deletedAt   // 백엔드가 camelCase로 응답
        case activityId  // 백엔드가 camelCase로 응답
        case lat
        case long
        case speed
        case altitude
        case seq
    }
    
    // Default initializer for manual creation
    init(
        id: Int,
        uuid: String,
        createdAt: Date,
        deletedAt: Date? = nil,
        activityId: Int,
        lat: Double,
        long: Double,
        speed: Double? = nil,
        altitude: Double? = nil,
        seq: Int
    ) {
        self.id = id
        self.uuid = uuid
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.activityId = activityId
        self.lat = lat
        self.long = long
        self.speed = speed
        self.altitude = altitude
        self.seq = seq
    }
    
    // Custom init to handle potential type mismatches from backend
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        uuid = try container.decode(String.self, forKey: .uuid)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        
        activityId = try container.decode(Int.self, forKey: .activityId)
        seq = try container.decode(Int.self, forKey: .seq)
        
        // Handle lat as String or Double
        if let latString = try? container.decode(String.self, forKey: .lat) {
            lat = Double(latString) ?? 0.0
        } else {
            lat = try container.decode(Double.self, forKey: .lat)
        }
        
        // Handle long as String or Double
        if let longString = try? container.decode(String.self, forKey: .long) {
            long = Double(longString) ?? 0.0
        } else {
            long = try container.decode(Double.self, forKey: .long)
        }
        
        // Handle speed as String or Double
        if let speedString = try? container.decode(String.self, forKey: .speed) {
            speed = Double(speedString)
        } else {
            speed = try container.decodeIfPresent(Double.self, forKey: .speed)
        }
        
        // Handle altitude as String or Double
        if let altitudeString = try? container.decode(String.self, forKey: .altitude) {
            altitude = Double(altitudeString)
        } else {
            altitude = try container.decodeIfPresent(Double.self, forKey: .altitude)
        }
    }
}

