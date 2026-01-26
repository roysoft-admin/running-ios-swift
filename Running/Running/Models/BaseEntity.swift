//
//  BaseEntity.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

protocol BaseEntityProtocol: Codable {
    var id: Int { get }
    var uuid: String { get }
    var createdAt: Date { get }
    var deletedAt: Date? { get }
}

struct BaseEntity: BaseEntityProtocol, Codable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
}


