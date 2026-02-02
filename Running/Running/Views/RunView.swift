//
//  RunView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct RunView: View {
    @StateObject private var viewModel = RunViewModel()
    @State private var showStartModal = false
    @State private var navigateToProgress = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
                ZStack {
            // Map Area - 전체 화면
                    ActivityMapView(routes: [], isInteractive: false)
                .ignoresSafeArea()
                    
            // Stats Area - 하단에 고정
                    VStack {
                        Spacer()
                
                VStack(spacing: 24) {
                    // Start Button
                    Button(action: {
                        showStartModal = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                            
                            Text("시작하기")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.emerald500)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    
                    // Ad Banner
                    Text("광고 영역")
                        .font(.system(size: 12))
                        .foregroundColor(.gray500)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.gray100)
                        .cornerRadius(12)
                }
                .padding(24)
                .background(Color.white)
                .padding(.bottom, 60) // 하단 탭 바 높이
            }
        }
        .background(Color.gray50)
        .sheet(isPresented: $showStartModal) {
            RunModeSelectionView(viewModel: viewModel) {
                navigateToProgress = true
            }
        }
        .fullScreenCover(isPresented: $navigateToProgress) {
            RunningInProgressView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showChallengeInfo) {
            ChallengeInfoView(viewModel: viewModel)
        }
        .loadingOverlay(isLoading: $viewModel.isLoading)
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .onChange(of: viewModel.startSuccess) { success in
            // 챌린지 시작 성공 시 러닝 화면으로 이동
            if let success = success, success {
                // 챌린지 정보 화면이 닫힌 후 러닝 화면 표시
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    navigateToProgress = true
                }
            }
        }
        .onAppear {
            // AppState의 사용자 정보를 ViewModel에 전달
            viewModel.currentUserUuid = appState.currentUser?.uuid
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray500)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.gray900)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.gray600)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.gray50)
        .cornerRadius(16)
    }
}

struct RunModeSelectionView: View {
    @ObservedObject var viewModel: RunViewModel
    @Environment(\.dismiss) var dismiss
    var onStartRunning: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("러닝 모드 선택")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray900)
                    .padding(.top, 24)
                
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.startRunning(type: .normal)
                    }) {
                        Text("일반 러닝")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.emerald500)
                            .cornerRadius(16)
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button(action: {
                        viewModel.startRunning(type: .aiChallenge)
                    }) {
                        ZStack {
                            Text("AI 챌린지 러닝")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue500, Color.purple500]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            
                            HStack {
                                Spacer()
                                
                                Text("+50P")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange500)
                                    .cornerRadius(12)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                    
                    Text("AI 챌린지는 날씨와 당신의 기록을 기반으로\n최적의 거리를 추천해드립니다")
                        .font(.system(size: 12))
                        .foregroundColor(.gray500)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .loadingOverlay(isLoading: $viewModel.isLoading)
            .errorAlert(errorMessage: $viewModel.errorMessage)
            .onChange(of: viewModel.startSuccess) { success in
                // 성공 시에만 화면 이동 (nil이 아니고 true일 때만)
                if let success = success, success {
                    dismiss()
                    // 약간의 딜레이 후 러닝 화면 표시
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onStartRunning()
                    }
                }
            }
            .onChange(of: viewModel.showChallengeInfo) { showChallengeInfo in
                // 챌린지 정보 화면이 표시되면 현재 모달 닫기
                if showChallengeInfo {
                    dismiss()
                }
            }
        }
    }
}


#Preview {
    RunView()
}

