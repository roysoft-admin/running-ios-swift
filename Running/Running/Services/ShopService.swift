//
//  ShopService.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class ShopService {
    static let shared = ShopService()
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - Get Shop Categories
    
    func getShopCategories(includeShopItems: Bool = false) -> AnyPublisher<ShopCategoriesListResponseDTO, NetworkError> {
        var endpoint = "/shop-categories"
        if includeShopItems {
            endpoint += "?include[shop-items]=true"
        }
        
        return apiService.request(
            endpoint: endpoint,
            method: .get
        )
    }
    
    // MARK: - Get Shop Items
    
    func getShopItems(
        shopCategoryId: Int? = nil,
        offset: Int? = nil,
        limit: Int? = nil
    ) -> AnyPublisher<ShopItemsListResponseDTO, NetworkError> {
        var queryItems: [URLQueryItem] = []
        
        if let shopCategoryId = shopCategoryId {
            queryItems.append(URLQueryItem(name: "shop_category_id", value: String(shopCategoryId)))
        }
        
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        var endpoint = "/shop-items"
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        return apiService.request(
            endpoint: endpoint,
            method: .get
        )
    }
    
    // MARK: - Create User Shop Item (Purchase)
    
    func createUserShopItem(
        userUuid: String,
        shopItemUuid: String,
        authUuid: String? = nil
    ) -> AnyPublisher<UserShopItemResponseDTO, NetworkError> {
        var dto = CreateUserShopItemDTO(
            userUuid: userUuid,
            shopItemUuid: shopItemUuid,
            authUuid: authUuid
        )
        
        return apiService.request(
            endpoint: "/user-shop-items",
            method: .post,
            body: dto
        )
    }
    
    // MARK: - Get User Shop Items
    
    func getUserShopItems(
        userUuid: String? = nil,
        offset: Int? = nil,
        limit: Int? = nil
    ) -> AnyPublisher<UserShopItemsListResponseDTO, NetworkError> {
        var queryItems: [URLQueryItem] = []
        
        if let userUuid = userUuid {
            queryItems.append(URLQueryItem(name: "user_uuid", value: userUuid))
        }
        
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        var endpoint = "/user-shop-items"
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

