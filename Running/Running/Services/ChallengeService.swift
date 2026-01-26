//
//  ChallengeService.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class ChallengeService {
    static let shared = ChallengeService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Create Challenge
    
    func createChallenge(userUuid: String) -> AnyPublisher<ChallengeResponseDTO, NetworkError> {
        let dto = CreateChallengeDTO(userUuid: userUuid)
        
        return apiService.request(
            endpoint: "/challenges",
            method: .post,
            body: dto
        )
    }
    
    // MARK: - Get Challenges
    
    func getChallenges(
        userUuid: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> AnyPublisher<ChallengesResponseDTO, NetworkError> {
        var queryItems: [URLQueryItem] = []
        
        if let userUuid = userUuid {
            queryItems.append(URLQueryItem(name: "user_uuid", value: userUuid))
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
        
        var endpoint = "/challenges"
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

