//
//  AppStateManager.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private let tokenManager = TokenManager.shared
    private let userService = UserService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthentication()
    }
    
    func checkAuthentication() {
        isAuthenticated = tokenManager.isAuthenticated
        if isAuthenticated {
            loadCurrentUser()
        }
    }
    
    func loadCurrentUser() {
        // TODO: Get user UUID from token or stored user data
        // For now, try to get from currentUser or use a default
        guard let userUuid = currentUser?.uuid else {
            // TODO: Get from token or stored data
            print("[AppStateManager] ⚠️ 사용자 UUID를 찾을 수 없습니다")
            return
        }
        
        userService.getUser(userUuid: userUuid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.isAuthenticated = false
                        self?.currentUser = nil
                    }
                },
                receiveValue: { [weak self] response in
                    self?.currentUser = response.user
                    self?.isAuthenticated = true
                }
            )
            .store(in: &cancellables)
    }
    
    func logout() {
        AuthService.shared.signOut()
        currentUser = nil
        isAuthenticated = false
    }
}


