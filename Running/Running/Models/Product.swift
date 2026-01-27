//
//  ShopItem.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

struct ShopCategory: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt
        case deletedAt
        case name
    }
}

struct ShopItem: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let name: String
    let shopCategoryId: Int
    let point: Int
    let order: Int
    let imageUrl: String?
    var shopCategory: ShopCategory?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt
        case deletedAt
        case name
        case shopCategoryId
        case point
        case order
        case imageUrl
        case shopCategory
    }
    
    // Computed properties for UI compatibility
    var points: Int { point }
    var image: String { "📦" } // Placeholder, should be added to entity if needed
    var category: ProductCategory {
        ProductCategory(rawValue: shopCategory?.name ?? "전체") ?? .all
    }
    
    enum ProductCategory: String, Codable {
        case all = "전체"
        case fnb = "F&B"
        case voucher = "상품권"
        case coupon = "쿠폰"
        case culture = "문화"
    }
}

struct UserShopItem: BaseEntityProtocol, Codable, Identifiable {
    let id: Int
    let uuid: String
    let createdAt: Date
    let deletedAt: Date?
    
    let userId: Int
    let shopItemId: Int
    var authUuid: String?
    var shopItem: ShopItem?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt
        case deletedAt
        case userId
        case shopItemId
        case authUuid
        case shopItem
    }
}

// Legacy typealias for backward compatibility
typealias Product = ShopItem

