//
//  PointService.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class PointService {
    static let shared = PointService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Create User Point (Earn/Use Points)
    
    func createUserPoint(
        userUuid: String,
        pointUuid: String,
        point: Int,  // 포인트 금액 (적립: 양수, 사용: 음수)
        referenceUuid: String? = nil
    ) -> AnyPublisher<UserPointResponseDTO, NetworkError> {
        var dto = CreateUserPointDTO(
            userUuid: userUuid,
            pointUuid: pointUuid,
            point: point,
            referenceUuid: referenceUuid
        )
        
        return apiService.request(
            endpoint: "/user-points",
            method: .post,
            body: dto
        )
    }
    
    // MARK: - Get User Points (History)
    
    func getUserPoints(
        startDate: Date? = nil,
        endDate: Date? = nil,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        userUuid: String? = nil,
        pointUuid: String? = nil,
        pointType: PointType? = nil,
        offset: Int? = nil,
        limit: Int? = nil
    ) -> AnyPublisher<UserPointsListResponseDTO, NetworkError> {
        var queryItems: [URLQueryItem] = []
        
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
        
        if let startedAt = startedAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
            queryItems.append(URLQueryItem(name: "started_at", value: formatter.string(from: startedAt)))
        }
        
        if let endedAt = endedAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
            queryItems.append(URLQueryItem(name: "ended_at", value: formatter.string(from: endedAt)))
        }
        
        if let userUuid = userUuid {
            queryItems.append(URLQueryItem(name: "user_uuid", value: userUuid))
        }
        
        if let pointUuid = pointUuid {
            queryItems.append(URLQueryItem(name: "point_uuid", value: pointUuid))
        }
        
        if let pointType = pointType {
            queryItems.append(URLQueryItem(name: "point_type", value: pointType.rawValue))
        }
        
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        var endpoint = "/user-points"
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        return apiService.request(
            endpoint: endpoint,
            method: .get
        )
    }
    
    // MARK: - Get Points (Static Data)
    
    func getPoints() -> AnyPublisher<PointsListResponseDTO, NetworkError> {
        return apiService.request(
            endpoint: "/points",
            method: .get
        )
    }
}

