//
//  ProfileEditView.swift
//  Running
//
//  Created by Auto on 1/27/26.
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @StateObject private var viewModel = ProfileEditViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    /// 프로필 수정 후 상위(MyPage 등)에 변경된 User를 전달하기 위한 콜백
    var onUpdated: ((User) -> Void)? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Image Section
                VStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(Color.gray100)
                                .frame(width: 120, height: 120)
                            
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else if let thumbnailUrl = viewModel.thumbnailUrl, !thumbnailUrl.isEmpty {
                                AsyncImage(url: URL(string: thumbnailUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray400)
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray400)
                            }
                            
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.emerald500)
                                        .clipShape(Circle())
                                        .offset(x: -8, y: -8)
                                }
                            }
                        }
                    }
                    
                    Text("프로필 사진 변경")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray600)
                }
                .padding(.top, 16)
                
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
                        
                        GenderButton(
                            title: "기타",
                            isSelected: viewModel.selectedGender == .other
                        ) {
                            viewModel.selectedGender = .other
                        }
                    }
                }
                
                // Target Distance
                VStack(alignment: .leading, spacing: 8) {
                    Text("목표 거리 (km)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray700)
                    
                    TextField("목표 거리를 입력하세요", text: $viewModel.targetDistance)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedTextFieldStyle())
                }
                
                // Target Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("목표 시간 (분)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray700)
                    
                    TextField("목표 시간을 입력하세요", text: $viewModel.targetTime)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedTextFieldStyle())
                }
                
                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("체중 (kg)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray700)
                    
                    TextField("체중을 입력하세요", text: $viewModel.weight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedTextFieldStyle())
                }
                
                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("지역")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray700)
                    
                    TextField("지역을 입력하세요", text: $viewModel.location)
                        .textFieldStyle(RoundedTextFieldStyle())
                }
                
                // Save Button
                Button(action: {
                    viewModel.updateProfile()
                }) {
                    Text("저장하기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.emerald500)
                        .cornerRadius(16)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .padding(.bottom, 96) // 하단 탭바 공간 확보
        }
        .navigationTitle("프로필 수정")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = appState.currentUser {
                viewModel.loadUserData(user)
                viewModel.currentUserUuid = user.uuid
            }
        }
        .onChange(of: selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profileImage = image
                    // TODO: 이미지 업로드 API 호출 후 thumbnailUrl 설정
                }
            }
        }
        .onChange(of: viewModel.updateSuccess) { success in
            if success {
                // 업데이트된 유저가 있으면 AppState에 반영
                if let updated = viewModel.updatedUser {
                    appState.currentUser = updated
                    onUpdated?(updated)
                }
                dismiss()
            }
        }
        .loadingOverlay(isLoading: $viewModel.isLoading)
        .errorAlert(errorMessage: $viewModel.errorMessage)
    }
}

struct PhoneVerificationSection: View {
    @Binding var phoneNumber: String
    @Binding var verificationCode: String
    @Binding var isCodeSent: Bool
    @Binding var isVerified: Bool
    @Binding var countdown: Int
    
    let onSendCode: () -> Void
    let onVerifyCode: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("전화번호")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray700)
            
            VStack(spacing: 12) {
                // Phone Number Input
                HStack(spacing: 12) {
                    TextField("전화번호를 입력하세요", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isCodeSent)
                    
                    Button(action: onSendCode) {
                        Text(isCodeSent ? "재발송" : "인증번호 발송")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(phoneNumber.isEmpty ? Color.gray400 : Color.emerald500)
                            .cornerRadius(8)
                    }
                    .disabled(phoneNumber.isEmpty || (isCodeSent && countdown > 0))
                }
                
                if isCodeSent {
                    // Verification Code Input
                    HStack(spacing: 12) {
                        TextField("인증번호 6자리", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isVerified)
                        
                        if countdown > 0 {
                            Text("\(countdown / 60):\(String(format: "%02d", countdown % 60))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray600)
                                .frame(width: 60)
                        }
                        
                        Button(action: onVerifyCode) {
                            Text(isVerified ? "인증완료" : "인증하기")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(isVerified ? Color.gray400 : (verificationCode.count == 6 ? Color.emerald500 : Color.gray400))
                                .cornerRadius(8)
                        }
                        .disabled(isVerified || verificationCode.count != 6)
                    }
                }
            }
            .padding()
            .background(Color.gray50)
            .cornerRadius(12)
        }
    }
}

struct EmailVerificationSection: View {
    @Binding var email: String
    @Binding var verificationCode: String
    @Binding var isCodeSent: Bool
    @Binding var isVerified: Bool
    @Binding var countdown: Int
    
    let onSendCode: () -> Void
    let onVerifyCode: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("이메일")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray700)
            
            VStack(spacing: 12) {
                // Email Input
                HStack(spacing: 12) {
                    TextField("이메일을 입력하세요", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isCodeSent)
                    
                    Button(action: onSendCode) {
                        Text(isCodeSent ? "재발송" : "인증번호 발송")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(email.isEmpty ? Color.gray400 : Color.emerald500)
                            .cornerRadius(8)
                    }
                    .disabled(email.isEmpty || (isCodeSent && countdown > 0))
                }
                
                if isCodeSent {
                    // Verification Code Input
                    HStack(spacing: 12) {
                        TextField("인증번호 6자리", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isVerified)
                        
                        if countdown > 0 {
                            Text("\(countdown / 60):\(String(format: "%02d", countdown % 60))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray600)
                                .frame(width: 60)
                        }
                        
                        Button(action: onVerifyCode) {
                            Text(isVerified ? "인증완료" : "인증하기")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(isVerified ? Color.gray400 : (verificationCode.count == 6 ? Color.emerald500 : Color.gray400))
                                .cornerRadius(8)
                        }
                        .disabled(isVerified || verificationCode.count != 6)
                    }
                }
            }
            .padding()
            .background(Color.gray50)
            .cornerRadius(12)
        }
    }
}

