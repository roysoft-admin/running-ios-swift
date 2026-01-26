//
//  QNAService.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class QNAService {
    static let shared = QNAService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Create QNA
    
    func createQNA(
        type: QNAType,
        title: String,
        text: String,
        email: String
    ) -> AnyPublisher<QNAResponseDTO, NetworkError> {
        struct CreateQNARequest: Codable {
            let type: QNAType
            let title: String
            let text: String
            let email: String
        }
        
        let request = CreateQNARequest(
            type: type,
            title: title,
            text: text,
            email: email
        )
        
        return apiService.request(
            endpoint: "/qnas",
            method: .post,
            body: request
        )
    }
}

enum QNAType: String, Codable, CaseIterable {
    case question = "question"
    case suggestion = "suggestion"
    case etc = "etc"
    
    var displayName: String {
        switch self {
        case .question:
            return "문의"
        case .suggestion:
            return "제안"
        case .etc:
            return "기타"
        }
    }
}

struct QNAResponseDTO: Codable {
    let qna: QNA
}

struct QNA: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let type: QNAType
    let title: String
    let text: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case type
        case title
        case text
        case email
    }
}

