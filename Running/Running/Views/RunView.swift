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
    @State private var showFullScreenMap = false
    @State private var navigateToProgress = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Map Area
                ZStack {
                    // 실제 맵 표시
                    ActivityMapView(routes: [], isInteractive: false)
                        .frame(height: 300)
                        .clipped()
                    
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showFullScreenMap = true
                                }
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray700)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .padding()
                        }
                        
                        Spacer()
                    }
                }
                .frame(height: 300) // Map 영역 높이 고정
                
                // Stats Area
                VStack(spacing: 24) {
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatBox(title: "거리", value: "0.00", unit: "km")
                        StatBox(title: "시간", value: "00:00", unit: "")
                        StatBox(title: "페이스", value: "0'00\"", unit: "/km")
                        StatBox(title: "칼로리", value: "0", unit: "kcal")
                    }
                    
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
                .padding(.bottom, 80) // 하단 바 공간 확보
            }
        }
        .background(Color.gray50)
        .sheet(isPresented: $showStartModal) {
            RunModeSelectionView(viewModel: viewModel) {
                navigateToProgress = true
            }
        }
        .fullScreenCover(isPresented: $showFullScreenMap) {
            FullScreenMapView()
                .transition(.opacity)
        }
        .fullScreenCover(isPresented: $navigateToProgress) {
            RunningInProgressView(viewModel: viewModel)
        }
        .loadingOverlay(isLoading: $viewModel.isLoading)
        .errorAlert(errorMessage: $viewModel.errorMessage)
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
                        dismiss()
                        // 약간의 딜레이 후 러닝 화면 표시
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onStartRunning()
                        }
                    }) {
                        Text("일반 러닝")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.emerald500)
                            .cornerRadius(16)
                    }
                    
                    Button(action: {
                        viewModel.startRunning(type: .aiChallenge)
                        dismiss()
                        // 약간의 딜레이 후 러닝 화면 표시
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onStartRunning()
                        }
                    }) {
                        ZStack {
                            Text("AI 챌린지 러닝")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue500, Color.purple]),
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
        }
    }
}

struct FullScreenMapView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isPresented = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 동일한 맵을 전체 화면으로 표시 (기존 맵이 확대되는 느낌)
                ActivityMapView(routes: [], isInteractive: true)
                    .ignoresSafeArea()
                    .opacity(isPresented ? 1 : 0)
                    .scaleEffect(isPresented ? 1 : 0.95)
                    .animation(.easeInOut(duration: 0.3), value: isPresented)
            }
            .navigationTitle("지도")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = true
                }
            }
        }
    }
}

#Preview {
    RunView()
}

