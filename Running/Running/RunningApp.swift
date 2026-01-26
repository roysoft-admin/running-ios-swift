//
//  RunningApp.swift
//  Running
//
//  Created by Ryan on 1/23/26.
//

import SwiftUI
import FirebaseCore
import Combine

@main
struct RunningApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appState = AppState()
    
    init() {
        // Firebase 초기화
        // GoogleService-Info.plist 파일이 프로젝트에 추가되어 있어야 합니다.
        // 설정 가이드: iOS/FIREBASE_SETUP_GUIDE.md 참조
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var showSplash: Bool = true
    @Published var isLoggedIn: Bool = false
    @Published var isSignedUp: Bool = false
    @Published var isCheckingAuth: Bool = false  // 자동 로그인 체크 중
    @Published var currentUser: User?  // 현재 로그인한 사용자 정보
    @Published var selectedTab: BottomNavView.Tab = .home  // 현재 선택된 탭
    
    /// 탭을 전환합니다
    func switchToTab(_ tab: BottomNavView.Tab) {
        selectedTab = tab
    }
    
    private let authService = AuthService.shared
    private let tokenManager = TokenManager.shared
    private let appStartTime: Date = Date()  // 앱 시작 시간
    private let minimumSplashDuration: TimeInterval = 1.0  // 최소 스플래시 표시 시간 (1초)
    
    init() {
        // 앱 시작 시 자동 로그인 체크
        checkAutoLogin()
        
        // refreshToken이 없으면 최소 1초 후 스플래시 숨김
        if tokenManager.refreshToken == nil {
            ensureMinimumSplashDuration {
                self.showSplash = false
            }
        }
    }
    
    // MARK: - Minimum Splash Duration
    
    /// 최소 스플래시 표시 시간(1초)을 보장하는 헬퍼 함수
    private func ensureMinimumSplashDuration(completion: @escaping () -> Void) {
        let elapsed = Date().timeIntervalSince(appStartTime)
        let remaining = max(0, minimumSplashDuration - elapsed)
        
        if remaining > 0 {
            print("[AppState] 🔵 스플래시 최소 표시 시간 보장: \(remaining)초 대기")
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
                completion()
            }
        } else {
            print("[AppState] ✅ 이미 최소 표시 시간 경과, 즉시 완료")
            completion()
        }
    }
    
    // MARK: - Auto Login
    
    func checkAutoLogin() {
        print("[AppState] 🔵 자동 로그인 체크 시작")
        
        // refreshToken이 없으면 로그인 화면으로
        guard let refreshToken = tokenManager.refreshToken, !refreshToken.isEmpty else {
            print("[AppState] ❌ refreshToken이 없습니다. 로그인 화면으로 이동")
            isLoggedIn = false
            isCheckingAuth = false
            // refreshToken이 없을 때도 최소 1초 스플래시 유지
            ensureMinimumSplashDuration {
                self.showSplash = false
            }
            return
        }
        
        print("[AppState] ✅ refreshToken 발견, 토큰 갱신 시도")
        isCheckingAuth = true
        
        // refreshToken으로 새 토큰 발급 시도
        authService.refreshToken()
            .flatMap { [weak self] _ -> AnyPublisher<UserResponseDTO, NetworkError> in
                guard let self = self else {
                    return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
                }
                
                // JWT 토큰에서 사용자 UUID 추출
                guard let accessToken = self.tokenManager.accessToken,
                      let userUuid = self.extractUserUuidFromToken(accessToken) else {
                    print("[AppState] ⚠️ JWT 토큰에서 사용자 UUID를 추출할 수 없습니다")
                    return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
                }
                
                print("[AppState] ✅ JWT에서 사용자 UUID 추출: \(userUuid)")
                
                // 사용자 정보 가져오기
                let userService = UserService.shared
                return userService.getUser(userUuid: userUuid)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isCheckingAuth = false
                    
                    if case .failure(let error) = completion {
                        print("[AppState] ❌ 토큰 갱신 또는 사용자 정보 로드 실패: \(error)")
                        // refreshToken 만료 또는 유효하지 않음 -> 로그인 화면으로
                        self.isLoggedIn = false
                        self.currentUser = nil
                        self.tokenManager.clearTokens()  // 만료된 토큰 삭제
                        // 자동 로그인 실패 후 최소 1초 스플래시 유지 후 숨김
                        self.ensureMinimumSplashDuration {
                            self.showSplash = false
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    print("[AppState] ✅ 토큰 갱신 및 사용자 정보 로드 성공: UUID=\(response.user.uuid)")
                    self.currentUser = response.user
                    self.isCheckingAuth = false
                    // 자동 로그인 완료 후 최소 1초 스플래시 유지 후 숨김
                    self.ensureMinimumSplashDuration {
                        self.showSplash = false
                        self.isLoggedIn = true
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - JWT Token Helper
    
    /// JWT 토큰에서 사용자 UUID를 추출합니다
    private func extractUserUuidFromToken(_ token: String) -> String? {
        // JWT는 base64url로 인코딩된 3개의 부분으로 구성: header.payload.signature
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            print("[AppState] ❌ JWT 토큰 형식이 올바르지 않습니다")
            return nil
        }
        
        // payload 부분 디코딩
        let payload = parts[1]
        
        // base64url 디코딩 (Swift의 base64는 base64url과 약간 다름)
        var base64 = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // 패딩 추가
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uuid = json["uuid"] as? String else {
            print("[AppState] ❌ JWT payload에서 uuid를 찾을 수 없습니다")
            return nil
        }
        
        return uuid
    }
    
    // MARK: - Logout
    
    func logout() {
        print("[AppState] 🔵 로그아웃 시작")
        authService.signOut()
        isLoggedIn = false
        currentUser = nil  // 사용자 정보도 삭제
        print("[AppState] ✅ 로그아웃 완료, 토큰 삭제됨")
    }
}
