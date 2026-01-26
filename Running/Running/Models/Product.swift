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
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
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
    var shopCategory: ShopCategory?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case name
        case shopCategoryId = "shop_category_id"
        case point
        case order
        case shopCategory = "shop_category"
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
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
        case userId = "user_id"
        case shopItemId = "shop_item_id"
        case authUuid = "auth_uuid"
        case shopItem = "shop_item"
    }
}

// Legacy typealias for backward compatibility
typealias Product = ShopItem

