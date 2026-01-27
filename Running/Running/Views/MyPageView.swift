//
//  MyPageView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct MyPageView: View {
    @StateObject private var viewModel = MyPageViewModel()
    @State private var showWebView: Bool = false
    @State private var webViewURL: WebViewURL?
    @State private var showProfileEdit: Bool = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Section
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            if let thumbnailUrl = viewModel.user?.thumbnailUrl, !thumbnailUrl.isEmpty {
                                AsyncImage(url: URL(string: thumbnailUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.user?.name ?? "사용자")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let email = viewModel.user?.email, !email.isEmpty {
                                Text(email)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
                .padding(24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gradientStart, Color.gradientEnd]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Points Section
                VStack(spacing: 16) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "bitcoinsign.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.emerald500)
                            
                            Text("포인트 내역")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray900)
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: PointHistoryView()) {
                            Text("전체보기")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.emerald500)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("보유 포인트")
                                .font(.system(size: 12))
                                .foregroundColor(.gray500)
                            
                            Text("\(viewModel.user?.point ?? 0)P")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.gray900)
                        }
                        
                        Spacer()
                        
                        Button("사용하기") {
                            // Shop 화면으로 이동
                            appState.selectedTab = .shop
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.emerald500)
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("이번 달 획득")
                                .font(.system(size: 12))
                                .foregroundColor(.gray500)
                            
                            Spacer()
                            
                            Text("+\(viewModel.monthlyEarned)P")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.emerald500)
                        }
                        
                        HStack {
                            Text("이번 달 사용")
                                .font(.system(size: 12))
                                .foregroundColor(.gray500)
                            
                            Spacer()
                            
                            Text("-\(viewModel.monthlyUsed)P")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray900)
                        }
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.top, -16)
                .padding(.bottom, 16)
                
                // Profile Edit / 인증 Section
                MenuSection(title: nil, items: [
                    MenuItem(icon: "person", title: "프로필 수정", action: {
                        showProfileEdit = true
                    }),
                    MenuItem(icon: "phone", title: "전화번호 인증", action: {
                        viewModel.showPhoneVerification = true
                    }),
                    MenuItem(icon: "envelope", title: "이메일 변경", subtitle: viewModel.user?.email ?? "", action: {
                        viewModel.showEmailVerification = true
                    })
                ])
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Settings Section (푸시 알림만 사용)
                MenuSection(title: "설정", items: [
                    MenuItem(icon: "bell", title: "푸시 알림", hasToggle: true, toggleValue: Binding(
                        get: { viewModel.pushEnabled },
                        set: { viewModel.updatePushNotification(enabled: $0) }
                    ))
                ])
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Terms & Policy Section
                MenuSection(title: "약관 및 정책", items: [
                    MenuItem(icon: "doc.text", title: "이용약관", action: {
                        webViewURL = .terms
                        showWebView = true
                    }),
                    MenuItem(icon: "shield", title: "개인정보처리방침", action: {
                        webViewURL = .privacy
                        showWebView = true
                    }),
                    MenuItem(icon: "mappin", title: "위치기반서비스 이용약관", action: {
                        webViewURL = .location
                        showWebView = true
                    })
                ])
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Support Section
                MenuSection(title: "고객 지원", items: [
                    MenuItem(icon: "message", title: "문의하기", action: {
                        viewModel.showInquiryModal = true
                    })
                ])
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Logout
                Button(action: {
                    print("[MyPageView] 🔵 로그아웃 버튼 클릭")
                    appState.logout()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.square")
                            .font(.system(size: 18))
                        
                        Text("로그아웃")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // App Version
                Text("v1.0.0")
                    .font(.system(size: 12))
                    .foregroundColor(.gray400)
                    .padding(.bottom, 96) // 하단 바 공간 확보 (16 + 80)
            }
        }
        .background(Color.gray50)
        .loadingOverlay(isLoading: $viewModel.isLoading)
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .sheet(isPresented: $viewModel.showInquiryModal) {
            InquiryModalView()
        }
        .sheet(isPresented: $viewModel.showEmailVerification) {
            EmailVerificationModalView()
        }
        .sheet(isPresented: $viewModel.showPhoneVerification) {
            PhoneVerificationModalView()
        }
        .sheet(isPresented: $showWebView) {
            if let url = webViewURL {
                WebViewScreen(urlString: url.urlString, title: url.title)
            }
        }
        .sheet(isPresented: $showProfileEdit) {
            NavigationView {
                ProfileEditView { updatedUser in
                    // 프로필 수정 후 마이페이지 이름/정보를 즉시 갱신
                    viewModel.user = updatedUser
                }
            }
        }
        .onAppear {
            viewModel.currentUserUuid = appState.currentUser?.uuid
        }
    }
}

struct MenuSection: View {
    let title: String?
    let items: [MenuItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = title {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray500)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
            }
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    MenuItemView(item: item)
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
        }
    }
}

struct MenuItem {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var hasToggle: Bool = false
    var toggleValue: Binding<Bool>? = nil
    var action: (() -> Void)? = nil
}

struct MenuItemView: View {
    let item: MenuItem
    
    var body: some View {
        Button(action: {
            item.action?()
        }) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.gray600)
                    .frame(width: 24)
                
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray900)
                
                if let subtitle = item.subtitle {
                    Spacer()
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray500)
                }
                
                Spacer()
                
                if item.hasToggle, let toggleValue = item.toggleValue {
                    Toggle("", isOn: toggleValue)
                        .labelsHidden()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray400)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct EmailVerificationModalView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("이메일 인증 모달")
                    .padding()
            }
            .navigationTitle("이메일 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PhoneVerificationModalView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("전화번호 인증 모달")
                    .padding()
            }
            .navigationTitle("전화번호 인증")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MyPageView()
}

