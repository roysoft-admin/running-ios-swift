//
//  LoginViewModel.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var shouldNavigateToSignUp: Bool = false
    @Published var loginSuccess: Bool = false
    @Published var signUpToken: String?
    @Published var signUpProvider: SignUpView.SocialProvider?
    
    private let authService = AuthService.shared
    private let firebaseAuthService = FirebaseAuthService.shared
    var appState: AppState?  // AppState 참조 (외부에서 주입)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Google Sign In
    
    func loginWithGoogle() {
        print("[LoginViewModel] 🔵 Google 로그인 시작")
        isLoading = true
        errorMessage = nil
        
        firebaseAuthService.signInWithGoogle()
            .receive(on: DispatchQueue.main)
            .mapError { error in
                print("[LoginViewModel] ❌ Google Sign-In 에러: \(error.localizedDescription)")
                return NetworkError.unknown
            }
            .flatMap { [weak self] result -> AnyPublisher<SignInResponseDTO, NetworkError> in
                guard let self = self else {
                    print("[LoginViewModel] ❌ self가 nil입니다.")
                    return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
                }
                
                print("[LoginViewModel] ✅ Google Sign-In 성공, ID token: \(result.userID.prefix(50))...")
                
                // Store ID token for potential sign up
                self.signUpToken = result.userID
                let dto = SignInDTO(googleToken: result.userID, appleToken: nil, kakaoToken: nil, naverToken: nil)
                
                print("[LoginViewModel] 🔵 백엔드 로그인 API 요청 시작")
                print("[LoginViewModel] 📤 요청 DTO: googleToken=\(result.userID.prefix(50))..., appleToken=nil, kakaoToken=nil, naverToken=nil")
                
                return self.authService.signIn(dto: dto)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    switch completion {
                    case .finished:
                        print("[LoginViewModel] ✅ 로그인 프로세스 완료")
                    case .failure(let error):
                        print("[LoginViewModel] ❌ 로그인 실패: \(error)")
                        print("[LoginViewModel] ❌ 에러 타입: \(type(of: error))")
                        
                        if case .serverError(let code, let message) = error {
                            print("[LoginViewModel] ❌ 서버 에러 - 코드: \(code), 메시지: \(message ?? "nil")")
                            
                            // Check if user needs to sign up (404 or specific error code)
                            if code == 404 {
                                print("[LoginViewModel] 🔵 사용자 미등록 (404), 회원가입 화면으로 이동")
                                self?.signUpProvider = .google
                                self?.shouldNavigateToSignUp = true
                            } else {
                                print("[LoginViewModel] ❌ 서버 에러로 인한 로그인 실패")
                                self?.errorMessage = error.errorDescription
                            }
                        } else {
                            print("[LoginViewModel] ❌ 네트워크 에러 또는 기타 에러")
                            self?.errorMessage = error.errorDescription
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    print("[LoginViewModel] ✅ 백엔드 로그인 API 응답 성공")
                    print("[LoginViewModel] 📥 응답 받음 - accessToken 존재: \(response.accessToken != nil), refreshToken 존재: \(response.refreshToken != nil)")
                    
                    if let accessToken = response.accessToken {
                        print("[LoginViewModel] ✅ Access Token 저장됨: \(accessToken.prefix(20))...")
                    }
                    if let refreshToken = response.refreshToken {
                        print("[LoginViewModel] ✅ Refresh Token 저장됨: \(refreshToken.prefix(20))...")
                    }
                    if let isNewUser = response.isNewUser {
                        print("[LoginViewModel] ✅ 신규 사용자 여부: \(isNewUser)")
                    }
                    
                    // 사용자 정보를 AppState에 저장
                    self?.appState?.currentUser = response.user
                    print("[LoginViewModel] ✅ 사용자 정보 저장됨: UUID=\(response.user.uuid), 이름=\(response.user.name ?? "nil")")
                    
                    print("[LoginViewModel] 🔵 로그인 성공, 화면 이동 준비")
                    self?.loginSuccess = true
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Apple Sign In
    
    func loginWithApple() {
        isLoading = true
        errorMessage = nil
        
        firebaseAuthService.signInWithApple()
            .receive(on: DispatchQueue.main)
            .mapError { _ in NetworkError.unknown }
            .flatMap { [weak self] result -> AnyPublisher<SignInResponseDTO, NetworkError> in
                guard let self = self else {
                    return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
                }
                // Store userID for potential sign up
                self.signUpToken = result.userID
                let dto = SignInDTO(googleToken: nil, appleToken: result.userID, kakaoToken: nil, naverToken: nil)
                return self.authService.signIn(dto: dto)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        if case .serverError(let code, let message) = error, code == 404 {
                            self?.signUpProvider = .apple
                            self?.shouldNavigateToSignUp = true
                        } else {
                            self?.errorMessage = error.errorDescription
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    // 사용자 정보를 AppState에 저장
                    self?.appState?.currentUser = response.user
                    self?.loginSuccess = true
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Kakao Sign In
    
    func loginWithKakao(token: String) {
        isLoading = true
        errorMessage = nil
        
        let dto = SignInDTO(googleToken: nil, appleToken: nil, kakaoToken: token, naverToken: nil)
        
        authService.signIn(dto: dto)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        if case .serverError(let code, let message) = error, code == 404 {
                            self?.shouldNavigateToSignUp = true
                        } else {
                            self?.errorMessage = error.errorDescription
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    self?.loginSuccess = true
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Naver Sign In
    
    func loginWithNaver(token: String) {
        isLoading = true
        errorMessage = nil
        
        let dto = SignInDTO(googleToken: nil, appleToken: nil, kakaoToken: nil, naverToken: token)
        
        authService.signIn(dto: dto)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        if case .serverError(let code, let message) = error, code == 404 {
                            self?.shouldNavigateToSignUp = true
                        } else {
                            self?.errorMessage = error.errorDescription
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    self?.loginSuccess = true
                }
            )
            .store(in: &cancellables)
    }
}

