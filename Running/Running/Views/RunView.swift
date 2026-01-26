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
    
    var body: some View {
        ZStack {
            Color.gray50.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Map Area
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.emerald100, Color.blue50]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 16) {
                        Image(systemName: "map")
                            .font(.system(size: 96))
                            .foregroundColor(.gray400.opacity(0.5))
                        
                        Text("Map View")
                            .font(.system(size: 14))
                            .foregroundColor(.gray400)
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {}) {
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
            }
        }
        .sheet(isPresented: $showStartModal) {
            RunModeSelectionView(viewModel: viewModel)
        }
        .loadingOverlay(isLoading: $viewModel.isLoading)
        .errorAlert(errorMessage: $viewModel.errorMessage)
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
    @State private var navigateToProgress = false
    
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
                        navigateToProgress = true
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
                        navigateToProgress = true
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
        .fullScreenCover(isPresented: $navigateToProgress) {
            RunningInProgressView(viewModel: viewModel)
        }
    }
}

#Preview {
    RunView()
}

