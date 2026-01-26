//
//  ActivityService.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class ActivityService {
    static let shared = ActivityService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Get Activities
    
    func getActivities(
        startDate: Date? = nil,
        endDate: Date? = nil,
        userUuid: String? = nil
    ) -> AnyPublisher<ActivitiesListResponseDTO, NetworkError> {
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
        
        if let userUuid = userUuid {
            queryItems.append(URLQueryItem(name: "user_uuid", value: userUuid))
        }
        
        var endpoint = "/activities"
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        return apiService.request(
            endpoint: endpoint,
            method: .get
        )
    }
    
    // MARK: - Get Activity
    
    func getActivity(activityUuid: String) -> AnyPublisher<ActivityResponseDTO, NetworkError> {
        return apiService.request(
            endpoint: "/activities/\(activityUuid)",
            method: .get
        )
    }
    
    // MARK: - Create Activity (Start Running)
    
    func createActivity(
        userUuid: String,
        challengeUuid: String? = nil,
        startTime: Date
    ) -> AnyPublisher<ActivityResponseDTO, NetworkError> {
        print("[ActivityService] 🔵 createActivity 요청 시작")
        print("[ActivityService] 📤 userUuid=\(userUuid), challengeUuid=\(challengeUuid ?? "nil"), startTime=\(startTime)")
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var dto = CreateActivityDTO(
            userUuid: userUuid,
            challengeUuid: challengeUuid,
            startTime: formatter.string(from: startTime)
        )
        
        return apiService.request(
            endpoint: "/activities",
            method: .post,
            body: dto
        )
        .handleEvents(
            receiveOutput: { response in
                print("[ActivityService] ✅ createActivity 성공: activity.uuid=\(response.activity.uuid)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("[ActivityService] ❌ createActivity 실패: \(error)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Update Activity (End Running)
    
    func updateActivity(
        activityUuid: String,
        distance: Double? = nil,
        endTime: Date? = nil,
        averageSpeed: Double? = nil,
        calories: Int? = nil
    ) -> AnyPublisher<ActivityResponseDTO, NetworkError> {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var dto = UpdateActivityDTO()
        dto.distance = distance
        dto.endTime = endTime != nil ? formatter.string(from: endTime!) : nil
        dto.averageSpeed = averageSpeed
        dto.calories = calories
        
        return apiService.request(
            endpoint: "/activities/\(activityUuid)",
            method: .put,
            body: dto
        )
    }
    
    // MARK: - Create Activity Route
    
    func createActivityRoute(
        activityUuid: String,
        lat: Double,
        long: Double,
        speed: Double? = nil,
        altitude: Double? = nil,
        seq: Int
    ) -> AnyPublisher<ActivityRouteResponseDTO, NetworkError> {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var dto = CreateActivityRouteDTO(
            createdAt: formatter.string(from: Date()),
            activityUuid: activityUuid,
            lat: lat,
            long: long,
            speed: speed,
            altitude: altitude,
            seq: seq
        )
        
        return apiService.request(
            endpoint: "/activity-routes",
            method: .post,
            body: dto
        )
    }
}

struct ActivityRouteResponseDTO: Codable {
    let activityRoute: ActivityRoute
    
    enum CodingKeys: String, CodingKey {
        case activityRoute = "activity-route"
    }
}

