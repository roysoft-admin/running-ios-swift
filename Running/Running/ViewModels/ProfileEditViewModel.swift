//
//  ProfileEditViewModel.swift
//  Running
//
//  Created by Auto on 1/27/26.
//

import Foundation
import Combine
import SwiftUI

class ProfileEditViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var birthDate: Date?
    @Published var selectedGender: User.Gender?
    @Published var thumbnailUrl: String?
    @Published var targetDistance: String = ""
    @Published var targetTime: String = ""
    @Published var weight: String = ""
    @Published var location: String = ""
    
    // Phone verification
    @Published var phoneVerificationCode: String = ""
    @Published var isPhoneCodeSent: Bool = false
    @Published var isPhoneVerified: Bool = false
    @Published var phoneCountdown: Int = 0
    @Published var phoneAuthUuid: String?
    
    // Email verification
    @Published var emailVerificationCode: String = ""
    @Published var isEmailCodeSent: Bool = false
    @Published var isEmailVerified: Bool = false
    @Published var emailCountdown: Int = 0
    @Published var emailAuthUuid: String?
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var updateSuccess: Bool = false
    @Published var updatedUser: User?
    
    private let userService = UserService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    private var phoneTimer: Timer?
    private var emailTimer: Timer?
    
    var currentUserUuid: String?
    var initialUser: User?
    
    func loadUserData(_ user: User) {
        initialUser = user
        name = user.name ?? ""
        phoneNumber = "" // TODO: Get from Auth entity
        email = user.email ?? ""
        if let birthday = user.birthday {
            birthDate = birthday
        }
        selectedGender = user.gender
        thumbnailUrl = user.thumbnailUrl
        targetDistance = user.targetWeekDistance != nil ? String(format: "%.1f", user.targetWeekDistance!) : ""
        targetTime = user.targetTime != nil ? String(user.targetTime!) : ""
        weight = user.weight != nil ? String(format: "%.1f", user.weight!) : ""
        location = user.location ?? ""
    }
    
    func sendPhoneVerificationCode() {
        guard !phoneNumber.isEmpty else { return }
        
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
                    self?.phoneAuthUuid = response.authUuid
                    self?.isPhoneCodeSent = true
                    self?.startPhoneCountdown()
                    // 개발 환경에서만 코드 표시
                    if let code = response.code {
                        self?.errorMessage = "인증 코드: \(code)"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func verifyPhoneCode() {
        guard let authUuid = phoneAuthUuid, phoneVerificationCode.count == 6 else { return }
        
        isLoading = true
        authService.verify(authUuid: authUuid, code: phoneVerificationCode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.isPhoneVerified = true
                    self?.stopPhoneCountdown()
                }
            )
            .store(in: &cancellables)
    }
    
    func sendEmailVerificationCode() {
        guard !email.isEmpty else { return }
        
        isLoading = true
        authService.requestVerification(type: "email", email: email)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.emailAuthUuid = response.authUuid
                    self?.isEmailCodeSent = true
                    self?.startEmailCountdown()
                    // 개발 환경에서만 코드 표시
                    if let code = response.code {
                        self?.errorMessage = "인증 코드: \(code)"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func verifyEmailCode() {
        guard let authUuid = emailAuthUuid, emailVerificationCode.count == 6 else { return }
        
        isLoading = true
        authService.verify(authUuid: authUuid, code: emailVerificationCode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.isEmailVerified = true
                    self?.stopEmailCountdown()
                }
            )
            .store(in: &cancellables)
    }
    
    func updateProfile() {
        guard let userUuid = currentUserUuid else { return }
        
        isLoading = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var dto = UpdateUserDTO()
        dto.name = name.isEmpty ? nil : name
        dto.birthday = birthDate != nil ? formatter.string(from: birthDate!) : nil
        dto.gender = selectedGender
        dto.thumbnailUrl = thumbnailUrl
        dto.targetWeekDistance = Double(targetDistance)
        dto.targetTime = Int(targetTime)
        dto.weight = Double(weight)
        dto.location = location.isEmpty ? nil : location
        
        // Phone이 변경되었고 인증된 경우
        if !phoneNumber.isEmpty && isPhoneVerified, let authUuid = phoneAuthUuid {
            dto.authUuid = authUuid
        }
        // Email이 변경되었고 인증된 경우
        else if !email.isEmpty && isEmailVerified, let authUuid = emailAuthUuid {
            dto.authUuid = authUuid
        }
        
        userService.updateUser(userUuid: userUuid, dto: dto)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    // 업데이트된 유저 정보 저장 (AppState와 싱크용)
                    self?.updatedUser = response.user
                    self?.updateSuccess = true
                }
            )
            .store(in: &cancellables)
    }
    
    private func startPhoneCountdown() {
        phoneCountdown = 300 // 5분
        phoneTimer?.invalidate()
        phoneTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.phoneCountdown > 0 {
                self.phoneCountdown -= 1
            } else {
                self.stopPhoneCountdown()
            }
        }
    }
    
    private func stopPhoneCountdown() {
        phoneTimer?.invalidate()
        phoneTimer = nil
    }
    
    private func startEmailCountdown() {
        emailCountdown = 300 // 5분
        emailTimer?.invalidate()
        emailTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.emailCountdown > 0 {
                self.emailCountdown -= 1
            } else {
                self.stopEmailCountdown()
            }
        }
    }
    
    private func stopEmailCountdown() {
        emailTimer?.invalidate()
        emailTimer = nil
    }
    
    deinit {
        phoneTimer?.invalidate()
        emailTimer?.invalidate()
    }
}

