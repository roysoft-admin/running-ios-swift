//
//  PurchaseHistoryViewModel.swift
//  Running
//
//  Created by Auto on 1/27/26.
//

import Foundation
import Combine

class PurchaseHistoryViewModel: ObservableObject {
    @Published var purchaseHistory: [UserShopItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var currentUserUuid: String? {
        didSet {
            if currentUserUuid != nil {
                loadPurchaseHistory()
            }
        }
    }
    
    private let shopService = ShopService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadPurchaseHistory() {
        guard let userUuid = currentUserUuid else {
            return
        }
        
        isLoading = true
        
        shopService.getUserShopItems(userUuid: userUuid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.purchaseHistory = response.userShopItems
                }
            )
            .store(in: &cancellables)
    }
}

