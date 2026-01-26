//
//  SignUpViewModel.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class SignUpViewModel: ObservableObject {
    @Published var name: String = "홍길동"
    @Published var birthDate: Date?
    @Published var selectedGender: User.Gender?
    @Published var email: String = ""
    @Published var emailVerified: Bool = false
    @Published var agreedTerms: Bool = false
    @Published var agreedPrivacy: Bool = false
    @Published var agreedLocation: Bool = false
    @Published var agreedMarketing: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Social login tokens (Firebase ID tokens)
    var googleToken: String?
    var appleToken: String?
    var kakaoToken: String?
    var naverToken: String?
    
    // Helper to get current Firebase token if needed
    func getCurrentFirebaseToken(for provider: SignUpView.SocialProvider) {
        // If token is already set, use it
        // Otherwise, get from Firebase Auth
        switch provider {
        case .google, .apple:
            // Token should be passed from LoginViewModel
            break
        case .kakao, .naver:
            // These use OAuth tokens directly, not Firebase
            break
        }
    }
    
    @Published var signUpSuccess: Bool = false
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var canSignUp: Bool {
        // At least one social token is required
        (googleToken != nil || appleToken != nil || kakaoToken != nil || naverToken != nil) &&
        agreedTerms &&
        agreedPrivacy &&
        agreedLocation
    }
    
    func verifyEmail() {
        // TODO: 이메일 인증 API 구현 필요 (현재는 백엔드에 API 없음)
        emailVerified = true
    }
    
    func createSignUpDTO() -> SignUpDTO {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return SignUpDTO(
            googleToken: googleToken,
            appleToken: appleToken,
            kakaoToken: kakaoToken,
            naverToken: naverToken,
            name: name.isEmpty ? nil : name,
            birthday: birthDate != nil ? formatter.string(from: birthDate!) : nil,
            gender: selectedGender
        )
    }
    
    func signUp() {
        guard canSignUp else {
            errorMessage = "필수 항목을 모두 입력해주세요"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let dto = createSignUpDTO()
        
        authService.signUp(dto: dto)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.signUpSuccess = true
                }
            )
            .store(in: &cancellables)
    }
}

