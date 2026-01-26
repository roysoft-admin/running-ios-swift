//
//  LoginView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Binding var isLoggedIn: Bool
    @State private var showSignUp: Bool = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 48) {
                    // Logo Section
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 64, weight: .light))
                            .foregroundColor(Color.emerald500)
                        
                        VStack(spacing: 8) {
                            Text("RunReward")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.gray900)
                            
                            Text("달리고 보상받자")
                                .font(.system(size: 16))
                                .foregroundColor(.gray600)
                        }
                    }
                    
                    // Social Login Buttons
                    VStack(spacing: 12) {
                        SocialLoginButton(provider: .google) {
                            viewModel.loginWithGoogle()
                        }
                        
                        SocialLoginButton(provider: .apple) {
                            viewModel.loginWithApple()
                        }
                        
                        SocialLoginButton(provider: .kakao) {
                            // TODO: Kakao OAuth SDK 연동 필요
                            // Kakao SDK를 사용하여 토큰을 받은 후 호출
                            // viewModel.loginWithKakao(token: kakaoToken)
                            viewModel.errorMessage = "Kakao 로그인은 준비 중입니다."
                        }
                        
                        SocialLoginButton(provider: .naver) {
                            // TODO: Naver OAuth SDK 연동 필요
                            // Naver SDK를 사용하여 토큰을 받은 후 호출
                            // viewModel.loginWithNaver(token: naverToken)
                            viewModel.errorMessage = "Naver 로그인은 준비 중입니다."
                        }
                        
                        SocialLoginButton(provider: .facebook) {
                            // TODO: Facebook 로그인 (필요시)
                            viewModel.errorMessage = "Facebook 로그인은 준비 중입니다."
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
        }
        .onAppear {
            // AppState를 ViewModel에 전달
            viewModel.appState = appState
        }
        .onChange(of: viewModel.loginSuccess) { success in
            if success {
                print("[LoginView] 🔵 loginSuccess 변경 감지: \(success)")
                print("[LoginView] 🔵 메인 화면으로 이동")
                isLoggedIn = true
            }
        }
        .onChange(of: viewModel.shouldNavigateToSignUp) { shouldNavigate in
            if shouldNavigate {
                print("[LoginView] 🔵 shouldNavigateToSignUp 변경 감지: \(shouldNavigate)")
                print("[LoginView] 🔵 회원가입 화면으로 이동")
                showSignUp = true
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView(isSignedUp: $isLoggedIn)
        }
        .loadingOverlay(isLoading: $viewModel.isLoading)
        .errorAlert(errorMessage: $viewModel.errorMessage)
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}

