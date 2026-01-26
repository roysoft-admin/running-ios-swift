//
//  UserService.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class UserService {
    static let shared = UserService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Get User
    
    func getUser(userUuid: String) -> AnyPublisher<UserResponseDTO, NetworkError> {
        return apiService.request(
            endpoint: "/users/\(userUuid)",
            method: .get
        )
    }
    
    // MARK: - Update User
    
    func updateUser(userUuid: String, dto: UpdateUserDTO) -> AnyPublisher<UserResponseDTO, NetworkError> {
        return apiService.request(
            endpoint: "/users/\(userUuid)",
            method: .put,
            body: dto
        )
    }
    
    // MARK: - Delete User
    
    func deleteUser(userUuid: String) -> AnyPublisher<UserResponseDTO, NetworkError> {
        return apiService.request(
            endpoint: "/users/\(userUuid)",
            method: .delete
        )
    }
}

struct UpdateUserDTO: Codable {
    var name: String?
    var birthday: String? // YYYY-MM-DD format
    var gender: User.Gender?
    var thumbnailUrl: String?
    var isPush: Bool?
    var targetWeekDistance: Double?
    var targetTime: Int?
    var weight: Double?
    var isSubscription: Bool?
    var authUuid: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case birthday
        case gender
        case thumbnailUrl = "thumbnail_url"
        case isPush = "is_push"
        case targetWeekDistance = "target_week_distance"
        case targetTime = "target_time"
        case weight
        case isSubscription = "is_subscription"
        case authUuid = "auth_uuid"
    }
}

struct UserResponseDTO: Codable {
    let user: User
}


