//
//  SignUpView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) var dismiss
    @Binding var isSignedUp: Bool
    @State private var socialToken: String?
    @State private var socialProvider: SocialProvider?
    
    enum SocialProvider {
        case google
        case apple
        case kakao
        case naver
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("이름")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray700)
                        
                        TextField("이름을 입력하세요", text: $viewModel.name)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    // Birth Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("생년월일")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray700)
                        
                        DatePicker(
                            "생년월일",
                            selection: Binding(
                                get: { viewModel.birthDate ?? Date() },
                                set: { viewModel.birthDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .padding()
                        .background(Color.gray50)
                        .cornerRadius(12)
                    }
                    
                    // Gender
                    VStack(alignment: .leading, spacing: 8) {
                        Text("성별 (선택)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray700)
                        
                        HStack(spacing: 12) {
                            GenderButton(
                                title: "남성",
                                isSelected: viewModel.selectedGender == .male
                            ) {
                                viewModel.selectedGender = .male
                            }
                            
                            GenderButton(
                                title: "여성",
                                isSelected: viewModel.selectedGender == .female
                            ) {
                                viewModel.selectedGender = .female
                            }
                        }
                    }
                    
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("이메일")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray700)
                            
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        HStack(spacing: 8) {
                            TextField("example@email.com", text: $viewModel.email)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            Button("인증") {
                                viewModel.verifyEmail()
                            }
                            .buttonStyle(VerifyButtonStyle())
                        }
                        
                        Text("* 포인트 사용에 필요합니다")
                            .font(.system(size: 12))
                            .foregroundColor(.gray500)
                    }
                    
                    // Agreement Checkboxes
                    VStack(spacing: 12) {
                        AgreementRow(
                            title: "이용약관 동의 (필수)",
                            isAgreed: $viewModel.agreedTerms,
                            showViewButton: true
                        )
                        
                        AgreementRow(
                            title: "개인정보처리방침 (필수)",
                            isAgreed: $viewModel.agreedPrivacy,
                            showViewButton: true
                        )
                        
                        AgreementRow(
                            title: "위치정보 이용약관 (필수)",
                            isAgreed: $viewModel.agreedLocation,
                            showViewButton: true
                        )
                        
                        AgreementRow(
                            title: "마케팅 정보 수신 (선택)",
                            isAgreed: $viewModel.agreedMarketing,
                            showViewButton: false
                        )
                    }
                    .padding(.top, 8)
                    
                    // Sign Up Button
                    Button(action: {
                        viewModel.signUp()
                    }) {
                        Text("가입하기")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                viewModel.canSignUp ? Color.emerald500 : Color.gray400
                            )
                            .cornerRadius(16)
                    }
                    .disabled(!viewModel.canSignUp)
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .navigationTitle("회원가입")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gray900)
                    }
                }
            }
            .onAppear {
                // Set social token if available (from login flow)
                if let token = socialToken, let provider = socialProvider {
                    switch provider {
                    case .google:
                        viewModel.googleToken = token
                    case .apple:
                        viewModel.appleToken = token
                    case .kakao:
                        viewModel.kakaoToken = token
                    case .naver:
                        viewModel.naverToken = token
                    }
                }
            }
            .onChange(of: viewModel.signUpSuccess) { success in
                if success {
                    isSignedUp = true
                }
            }
            .loadingOverlay(isLoading: $viewModel.isLoading)
            .errorAlert(errorMessage: $viewModel.errorMessage)
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray50)
            .cornerRadius(12)
    }
}

struct VerifyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.emerald500)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct GenderButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? Color.emerald500 : .gray700)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.gray50)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.emerald500 : Color.gray200, lineWidth: 2)
                )
                .cornerRadius(12)
        }
    }
}

struct AgreementRow: View {
    let title: String
    @Binding var isAgreed: Bool
    let showViewButton: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                isAgreed.toggle()
            }) {
                Image(systemName: isAgreed ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24))
                    .foregroundColor(isAgreed ? Color.emerald500 : Color.gray400)
            }
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray900)
            
            Spacer()
            
            if showViewButton {
                Button("보기") {
                    // TODO: 약관 보기
                }
                .font(.system(size: 12))
                .foregroundColor(.gray500)
            }
        }
        .padding()
        .background(Color.gray50)
        .cornerRadius(12)
    }
}

#Preview {
    SignUpView(isSignedUp: .constant(false))
}
