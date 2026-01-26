//
//  ShopDTO.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

struct ShopItemResponseDTO: Codable {
    let shopItem: ShopItem
    
    enum CodingKeys: String, CodingKey {
        case shopItem = "shop-item"
    }
}

// 백엔드: GET /shop/items 응답
struct ShopItemsListResponseDTO: Codable {
    let shopItems: [ShopItem]  // 백엔드: shop-items
    let totalCount: Int        // 백엔드: total_count
    
    enum CodingKeys: String, CodingKey {
        case shopItems = "shop-items"
        case totalCount = "total_count"
    }
}

struct ShopCategoriesListResponseDTO: Codable {
    let shopCategories: [ShopCategory]
    
    enum CodingKeys: String, CodingKey {
        case shopCategories = "shop-categories"
    }
}

// 백엔드: POST /shop/user-shop-items - 상점 아이템 구매
struct CreateUserShopItemDTO: Codable {
    let userUuid: String        // 백엔드: user_uuid
    let shopItemUuid: String    // 백엔드: shop_item_uuid
    var authUuid: String?  // 백엔드: auth_uuid (optional)
    
    enum CodingKeys: String, CodingKey {
        case userUuid = "user_uuid"
        case shopItemUuid = "shop_item_uuid"
        case authUuid = "auth_uuid"
    }
}

struct UserShopItemResponseDTO: Codable {
    let userShopItem: UserShopItem
    
    enum CodingKeys: String, CodingKey {
        case userShopItem = "user-shop-item"
    }
}

// 백엔드: GET /shop/user-shop-items 응답
struct UserShopItemsListResponseDTO: Codable {
    let userShopItems: [UserShopItem]  // 백엔드: user-shop-items (kebab-case)
    let totalCount: Int?                // 백엔드: total_count (snake_case)
    
    enum CodingKeys: String, CodingKey {
        case userShopItems = "user-shop-items"  // 백엔드가 kebab-case로 응답
        case totalCount = "total_count"          // 백엔드가 snake_case로 응답
    }
}

