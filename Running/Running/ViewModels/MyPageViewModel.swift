//
//  MyPageViewModel.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class MyPageViewModel: ObservableObject {
    @Published var user: User?
    @Published var pushEnabled: Bool = true
    @Published var darkMode: Bool = false
    @Published var showInquiryModal: Bool = false
    @Published var showEmailVerification: Bool = false
    @Published var showPhoneVerification: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userService = UserService.shared
    private let pointViewModel = PointViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // TODO: Get current user UUID from app state
    var currentUserUuid: String? {
        didSet {
            if currentUserUuid != nil {
                loadData()
            }
        }
    }
    
    init() {
        // currentUserUuid가 설정되면 자동으로 loadData()가 호출됨
    }
    
    func loadData() {
        loadUser()
        loadPointHistory()
    }
    
    func loadUser() {
        guard let userUuid = currentUserUuid else {
            return
        }
        
        isLoading = true
        
        userService.getUser(userUuid: userUuid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.user = response.user
                    self?.pushEnabled = response.user.isPush
                }
            )
            .store(in: &cancellables)
    }
    
    func loadPointHistory() {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        pointViewModel.loadUserPoints(startDate: startOfMonth, endDate: endOfMonth)
    }
    
    func updateUser(name: String?, birthday: Date?, gender: User.Gender?, thumbnailUrl: String?, targetWeekDistance: Double?, targetTime: Int?, weight: Double?, authUuid: String?) {
        guard let user = user else { return }
        
        isLoading = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var dto = UpdateUserDTO()
        dto.name = name
        dto.birthday = birthday != nil ? formatter.string(from: birthday!) : nil
        dto.gender = gender
        dto.thumbnailUrl = thumbnailUrl
        dto.targetWeekDistance = targetWeekDistance
        dto.targetTime = targetTime
        dto.weight = weight
        dto.authUuid = authUuid
        
        userService.updateUser(userUuid: user.uuid, dto: dto)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.user = response.user
                }
            )
            .store(in: &cancellables)
    }
    
    func updatePushNotification(enabled: Bool) {
        guard let user = user else { return }
        
        var dto = UpdateUserDTO()
        dto.isPush = enabled
        
        userService.updateUser(userUuid: user.uuid, dto: dto)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.user = response.user
                    self?.pushEnabled = response.user.isPush
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteUser() {
        guard let user = user else { return }
        
        isLoading = true
        
        userService.deleteUser(userUuid: user.uuid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    // User deleted - should logout and clear tokens
                    print("[MyPageViewModel] ✅ 계정 삭제 완료, 토큰 삭제")
                    AuthService.shared.signOut()
                }
            )
            .store(in: &cancellables)
    }
    
    var monthlyEarned: Int {
        return pointViewModel.getMonthlyEarned()
    }
    
    var monthlyUsed: Int {
        return pointViewModel.getMonthlyUsed()
    }
}

