//
//  FirebaseAuthService.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import Combine
import CryptoKit

class FirebaseAuthService {
    static let shared = FirebaseAuthService()
    
    private init() {}
    
    // MARK: - Helper: Generate Random Nonce
    
    private func generateRandomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    // MARK: - Helper: SHA256 Hash
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Google Sign In (GoogleSignIn 9.1.0)
    // Firebase Auth를 거치지 않고 직접 Google Sign-In SDK 사용
    // userID를 반환하여 백엔드 API에 전달
    
    func signInWithGoogle() -> AnyPublisher<GoogleSignInResult, Error> {
        return Future { promise in
            print("[FirebaseAuthService] 🔵 Google 로그인 시작")
            
            // GoogleSignIn 9.1.0: GoogleService-Info.plist에서 clientID 가져오기
            guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let clientID = plist["CLIENT_ID"] as? String else {
                print("[FirebaseAuthService] ❌ GoogleService-Info.plist에서 CLIENT_ID를 찾을 수 없습니다.")
                promise(.failure(NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "GoogleService-Info.plist에서 CLIENT_ID를 찾을 수 없습니다."])))
                return
            }
            
            print("[FirebaseAuthService] ✅ CLIENT_ID 로드 성공: \(clientID.prefix(20))...")
            
            // GoogleSignIn 9.1.0: GIDConfiguration 설정
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            print("[FirebaseAuthService] ✅ GIDConfiguration 설정 완료")
            
            // Get root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                print("[FirebaseAuthService] ❌ Root view controller를 찾을 수 없습니다.")
                promise(.failure(NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Root view controller를 찾을 수 없습니다."])))
                return
            }
            
            print("[FirebaseAuthService] ✅ Root view controller 찾음, Google Sign-In 요청 시작")
            
            // GoogleSignIn 9.1.0: signIn(withPresenting:) 사용
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                if let error = error {
                    print("[FirebaseAuthService] ❌ Google Sign-In 에러: \(error.localizedDescription)")
                    print("[FirebaseAuthService] ❌ 에러 상세: \(error)")
                    DispatchQueue.main.async {
                        promise(.failure(error))
                    }
                    return
                }
                
                guard let user = result?.user else {
                    print("[FirebaseAuthService] ❌ Google 로그인 사용자 정보를 가져올 수 없습니다.")
                    DispatchQueue.main.async {
                        promise(.failure(NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google 로그인 사용자 정보를 가져올 수 없습니다."])))
                    }
                    return
                }
                
                print("[FirebaseAuthService] ✅ Google 사용자 정보 받음")
                
                // Google OAuth ID token 가져오기
                guard let googleIDToken = user.idToken?.tokenString else {
                    print("[FirebaseAuthService] ❌ Google ID token을 가져올 수 없습니다.")
                    DispatchQueue.main.async {
                        promise(.failure(NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google ID token을 가져올 수 없습니다."])))
                    }
                    return
                }
                
                let accessToken = user.accessToken.tokenString
                
                print("[FirebaseAuthService] ✅ Google OAuth ID token 받음: \(googleIDToken.prefix(50))...")
                
                // userID도 함께 저장 (참고용)
                let userID = user.userID ?? ""
                print("[FirebaseAuthService] ✅ Google userID: \(userID)")
                
                // 사용자 이름 정보
                let name = user.profile?.name ?? user.profile?.givenName
                if let name = name {
                    print("[FirebaseAuthService] ✅ 사용자 이름: \(name)")
                }
                
                // Google OAuth ID token을 Firebase ID token으로 변환
                print("[FirebaseAuthService] 🔵 Firebase Auth를 통해 Firebase ID token 생성 시작")
                let credential = GoogleAuthProvider.credential(withIDToken: googleIDToken, accessToken: accessToken)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("[FirebaseAuthService] ❌ Firebase Auth 로그인 실패: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            promise(.failure(error))
                        }
                        return
                    }
                    
                    print("[FirebaseAuthService] ✅ Firebase Auth 로그인 성공")
                    
                    // Firebase ID token 가져오기
                    Task {
                        do {
                            guard let firebaseUser = Auth.auth().currentUser else {
                                print("[FirebaseAuthService] ❌ Firebase 사용자 정보를 가져올 수 없습니다.")
                                DispatchQueue.main.async {
                                    promise(.failure(NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase 사용자 정보를 가져올 수 없습니다."])))
                                }
                                return
                            }
                            
                            let firebaseIDToken = try await firebaseUser.getIDToken()
                            print("[FirebaseAuthService] ✅ Firebase ID token 받음: \(firebaseIDToken.prefix(50))...")
                            
                            let result = GoogleSignInResult(
                                userID: firebaseIDToken, // Firebase ID token 사용
                                name: name
                            )
                            
                            print("[FirebaseAuthService] ✅ Google 로그인 성공, Firebase ID token 반환")
                            DispatchQueue.main.async {
                                promise(.success(result))
                            }
                        } catch {
                            print("[FirebaseAuthService] ❌ Firebase ID token 가져오기 실패: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                promise(.failure(error))
                            }
                        }
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Apple Sign In
    // Firebase Auth를 거치지 않고 직접 Apple Sign-In SDK 사용
    // appleUserID를 반환하여 백엔드 API에 전달
    
    func signInWithApple() -> AnyPublisher<AppleSignInResult, Error> {
        return Future { promise in
            // Generate nonce for Apple Sign In security
            let rawNonce = self.generateRandomNonce()
            let nonceHash = self.sha256(rawNonce)
            
            // Create Apple Sign In request
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = nonceHash
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            
            let delegate = AppleSignInDelegate { result in
                switch result {
                case .success(let credential):
                    // Apple userID 사용 (Firebase Auth를 거치지 않음)
                    let appleUserID = credential.user
                    
                    // 사용자 이름 정보 (첫 로그인 시에만 제공됨)
                    var name: String? = nil
                    if let fullName = credential.fullName {
                        let formatter = PersonNameComponentsFormatter()
                        name = formatter.string(from: fullName)
                    }
                    
                    let result = AppleSignInResult(
                        userID: appleUserID,
                        name: name
                    )
                    
                    DispatchQueue.main.async {
                        promise(.success(result))
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        promise(.failure(error))
                    }
                }
            }
            
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = delegate
            
            authorizationController.performRequests()
            
            // Keep delegate alive
            objc_setAssociatedObject(authorizationController, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Result Types

struct GoogleSignInResult {
    let userID: String  // 실제로는 ID token을 저장 (백엔드가 기대하는 형식)
    let name: String?
}

struct AppleSignInResult {
    let userID: String
    let name: String?
}

// MARK: - Apple Sign In Delegate

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorizationAppleIDCredential, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completion(.success(appleIDCredential))
        } else {
            completion(.failure(NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple 로그인 인증 정보를 가져올 수 없습니다."])))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}
