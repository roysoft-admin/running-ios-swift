//
//  PurchaseViewModel.swift
//  Running
//
//  Created by Auto on 1/27/26.
//

import Foundation
import Combine

class PurchaseViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var verificationCode: String = ""
    @Published var isCodeSent: Bool = false
    @Published var isVerified: Bool = false
    @Published var countdown: Int = 0
    @Published var authUuid: String? = nil
    @Published var agreedPurchase: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var purchaseSuccess: Bool = false
    
    let shopItem: ShopItem
    let currentPoints: Int
    var currentUserUuid: String?
    
    private let shopService = ShopService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?
    
    var remainingPoints: Int {
        currentPoints - shopItem.point
    }
    
    var canPurchase: Bool {
        agreedPurchase && isVerified && !isLoading && remainingPoints >= 0
    }
    
    init(shopItem: ShopItem, currentPoints: Int, initialPhoneNumber: String? = nil) {
        self.shopItem = shopItem
        self.currentPoints = currentPoints
        self.phoneNumber = initialPhoneNumber ?? ""
    }
    
    func sendVerificationCode() {
        guard !phoneNumber.isEmpty else {
            errorMessage = "전화번호를 입력해주세요"
            return
        }
        
        isLoading = true
        
        authService.requestVerification(type: "phone", phone: phoneNumber)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.authUuid = response.authUuid
                    self?.isCodeSent = true
                    self?.countdown = 180 // 3분
                    self?.startCountdown()
                    
                    // 개발 환경에서 코드 표시
                    if let code = response.code {
                        print("[PurchaseViewModel] 🔵 인증 코드: \(code)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func verifyCode() {
        guard verificationCode.count == 6 else {
            errorMessage = "6자리 인증번호를 입력해주세요"
            return
        }
        
        guard let authUuid = authUuid else {
            errorMessage = "인증 요청을 먼저 해주세요"
            return
        }
        
        isLoading = true
        
        authService.verify(authUuid: authUuid, code: verificationCode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success {
                        self?.isVerified = true
                        self?.stopCountdown()
                    } else {
                        self?.errorMessage = "인증에 실패했습니다"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func purchase() {
        guard canPurchase else {
            return
        }
        
        guard let userUuid = currentUserUuid else {
            errorMessage = "사용자 정보를 찾을 수 없습니다"
            return
        }
        
        guard currentPoints >= shopItem.point else {
            errorMessage = "포인트가 부족합니다"
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
            }
        )
        .store(in: &cancellables)
    }
    
    private func startCountdown() {
        stopCountdown()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.countdown > 0 {
                self.countdown -= 1
            } else {
                self.stopCountdown()
            }
        }
    }
    
    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    deinit {
        stopCountdown()
    }
}

