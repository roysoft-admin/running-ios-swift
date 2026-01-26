//
//  ShopViewModel.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class ShopViewModel: ObservableObject {
    @Published var currentPoints: Int = 0
    @Published var selectedCategory: ShopItem.ProductCategory = .all
    @Published var shopItems: [ShopItem] = []
    @Published var shopCategories: [ShopCategory] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var purchaseSuccess: Bool = false
    
    private let shopService = ShopService.shared
    private let userService = UserService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // TODO: Get current user UUID from app state
    var currentUserUuid: String?
    
    init() {
        loadShopCategories()
        loadShopItems()
        loadUserPoints()
    }
    
    func loadUserPoints() {
        guard let userUuid = currentUserUuid else {
            errorMessage = "사용자 정보를 찾을 수 없습니다"
            return
        }
        
        userService.getUser(userUuid: userUuid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.currentPoints = response.user.point
                }
            )
            .store(in: &cancellables)
    }
    
    func loadShopCategories() {
        shopService.getShopCategories(includeShopItems: false)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.shopCategories = response.shopCategories
                }
            )
            .store(in: &cancellables)
    }
    
    func loadShopItems() {
        isLoading = true
        
        shopService.getShopItems()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.shopItems = response.shopItems.sorted { $0.order < $1.order }
                }
            )
            .store(in: &cancellables)
    }
    
    var filteredProducts: [ShopItem] {
        if selectedCategory == .all {
            return shopItems
        }
        return shopItems.filter { $0.category == selectedCategory }
    }
    
    func purchaseProduct(_ shopItem: ShopItem, authUuid: String? = nil) {
        guard currentPoints >= shopItem.point else {
            errorMessage = "포인트가 부족합니다."
            return
        }
        
        guard let userUuid = currentUserUuid else {
            errorMessage = "사용자 정보를 찾을 수 없습니다"
            return
        }
        
        isLoading = true
        
        shopService.createUserShopItem(
            userUuid: userUuid,
            shopItemUuid: shopItem.uuid,
            authUuid: authUuid
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                }
            },
            receiveValue: { [weak self] _ in
                self?.purchaseSuccess = true
                // Refresh user points
                self?.loadUserPoints()
            }
        )
        .store(in: &cancellables)
    }
}

