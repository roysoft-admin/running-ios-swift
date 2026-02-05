//
//  User.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

struct User: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    var googleToken: String?
    var appleToken: String?
    var kakaoToken: String?
    var naverToken: String?
    var name: String?
    var email: String?
    var phone: String?
    var birthday: Date?
    var gender: Gender?
    var thumbnailUrl: String?
    var targetWeekDistance: Double?
    var targetTime: Int?
    var weight: Double?
    var point: Int
    var location: String?
    var isSubscription: Bool
    var isPush: Bool
    var challengeCount: Int
    
    // 커스텀 디코딩: targetWeekDistance가 String으로 올 수 있음
    init(from decoder: Decoder) throws {
        print("[User] 🔵 User 디코딩 시작")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        print("[User] 🔵 id 디코딩 중...")
        id = try container.decode(Int.self, forKey: .id)
        print("[User] ✅ id: \(id)")
        
        print("[User] 🔵 uuid 디코딩 중...")
        uuid = try container.decode(String.self, forKey: .uuid)
        print("[User] ✅ uuid: \(uuid)")
        
        print("[User] 🔵 createdAt 디코딩 중...")
        do {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
            print("[User] ✅ createdAt: \(createdAt)")
        } catch {
            print("[User] ❌ createdAt 디코딩 실패: \(error)")
            throw error
        }
        
        print("[User] 🔵 deletedAt 디코딩 중...")
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        print("[User] ✅ deletedAt: \(deletedAt?.description ?? "nil")")
        
        print("[User] 🔵 googleToken 디코딩 중...")
        googleToken = try container.decodeIfPresent(String.self, forKey: .googleToken)
        print("[User] ✅ googleToken: \(googleToken?.prefix(20) ?? "nil")...")
        
        appleToken = try container.decodeIfPresent(String.self, forKey: .appleToken)
        kakaoToken = try container.decodeIfPresent(String.self, forKey: .kakaoToken)
        naverToken = try container.decodeIfPresent(String.self, forKey: .naverToken)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        print("[User] ✅ name: \(name ?? "nil")")
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        birthday = try container.decodeIfPresent(Date.self, forKey: .birthday)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        
        // targetWeekDistance: String 또는 Double로 올 수 있음
        print("[User] 🔵 targetWeekDistance 디코딩 중...")
        if let targetWeekDistanceString = try? container.decodeIfPresent(String.self, forKey: .targetWeekDistance),
           let value = Double(targetWeekDistanceString) {
            targetWeekDistance = value
            print("[User] ✅ targetWeekDistance (String -> Double): \(value)")
        } else {
            targetWeekDistance = try container.decodeIfPresent(Double.self, forKey: .targetWeekDistance)
            print("[User] ✅ targetWeekDistance (Double): \(targetWeekDistance?.description ?? "nil")")
        }
        
        targetTime = try container.decodeIfPresent(Int.self, forKey: .targetTime)
        
        // weight: String 또는 Double로 올 수 있음
        if let weightString = try? container.decodeIfPresent(String.self, forKey: .weight),
           let value = Double(weightString) {
            weight = value
        } else {
            weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        }
        
        point = try container.decode(Int.self, forKey: .point)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        isSubscription = try container.decode(Bool.self, forKey: .isSubscription)
        isPush = try container.decode(Bool.self, forKey: .isPush)
        challengeCount = try container.decode(Int.self, forKey: .challengeCount)
        
        print("[User] ✅ User 디코딩 완료")
    }
    
    enum Gender: String, Codable {
        case male = "male"
        case female = "female"
        case other = "other"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt // 백엔드가 camelCase로 응답
        case deletedAt // 백엔드가 camelCase로 응답
        case googleToken // 백엔드가 camelCase로 응답
        case appleToken // 백엔드가 camelCase로 응답
        case kakaoToken // 백엔드가 camelCase로 응답
        case naverToken // 백엔드가 camelCase로 응답
        case name
        case email
        case phone
        case birthday
        case gender
        case thumbnailUrl // 백엔드가 camelCase로 응답
        case targetWeekDistance // 백엔드가 camelCase로 응답
        case targetTime // 백엔드가 camelCase로 응답
        case weight
        case point
        case location
        case isSubscription // 백엔드가 camelCase로 응답
        case isPush // 백엔드가 camelCase로 응답
        case challengeCount // 백엔드가 camelCase로 응답
    }
}

