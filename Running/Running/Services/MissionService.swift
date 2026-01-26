//
//  MissionService.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class MissionService {
    static let shared = MissionService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Get Missions
    
    func getMissions() -> AnyPublisher<MissionsListResponseDTO, NetworkError> {
        return apiService.request(
            endpoint: "/missions",
            method: .get
        )
    }
    
    // MARK: - Get User Missions
    
    func getUserMissions(
        userUuid: String? = nil,
        status: UserMissionStatus? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> AnyPublisher<UserMissionsListResponseDTO, NetworkError> {
        var queryItems: [URLQueryItem] = []
        
        if let userUuid = userUuid {
            queryItems.append(URLQueryItem(name: "user_uuid", value: userUuid))
        }
        
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        
        if let startDate = startDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            queryItems.append(URLQueryItem(name: "start_date", value: formatter.string(from: startDate)))
        }
        
        if let endDate = endDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            queryItems.append(URLQueryItem(name: "end_date", value: formatter.string(from: endDate)))
        }
        
        var endpoint = "/user-missions"
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        return apiService.request(
            endpoint: endpoint,
            method: .get
        )
    }
}


