//
//  ChallengeInfoView.swift
//  Running
//
//  Created by Auto on 1/30/26.
//

import SwiftUI

struct ChallengeInfoView: View {
    @ObservedObject var viewModel: RunViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.gray50.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        viewModel.showChallengeInfo = false
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.gray700)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("AI 챌린지")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray900)
                    
                    Spacer()
                    
                    // 균형을 위한 빈 공간
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 24) {
                        if let challenge = viewModel.pendingChallenge {
                            // 챌린지 정보 카드
                            VStack(spacing: 20) {
                                // 챌린지 설명
                                if let description = challenge.description, !description.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("챌린지 설명")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.gray600)
                                        
                                        Text(description)
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray900)
                                            .lineSpacing(4)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(20)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                }
                                
                                // 목표 정보
                                VStack(spacing: 16) {
                                    Text("목표")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.gray900)
                                    
                                    HStack(spacing: 24) {
                                        VStack(spacing: 8) {
                                            Text("거리")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray600)
                                            
                                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                if let targetDistance = challenge.targetDistance {
                                                    Text(String(format: "%.1f", targetDistance))
                                                        .font(.system(size: 32, weight: .bold))
                                                        .foregroundColor(.emerald500)
                                                } else {
                                                    Text("미정")
                                                        .font(.system(size: 32, weight: .bold))
                                                        .foregroundColor(.gray400)
                                                }
                                                Text("km")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.gray600)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        VStack(spacing: 8) {
                                            Text("시간")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray600)
                                            
                                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                if let targetTime = challenge.targetTime {
                                                    Text("\(targetTime)")
                                                        .font(.system(size: 32, weight: .bold))
                                                        .foregroundColor(.blue500)
                                                } else {
                                                    Text("미정")
                                                        .font(.system(size: 32, weight: .bold))
                                                        .foregroundColor(.gray400)
                                                }
                                                Text("분")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.gray600)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(24)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            }
                            .padding(.horizontal, 20)
                            
                            // 시작 버튼
                            Button(action: {
                                viewModel.startChallengeRunning()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 20))
                                    
                                    Text("시작하기")
                                        .font(.system(size: 18, weight: .bold))
                                }
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
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 20)
                            .disabled(viewModel.isLoading)
                            
                            // 취소 버튼
                            Button(action: {
                                viewModel.showChallengeInfo = false
                                dismiss()
                            }) {
                                Text("취소")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray600)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        } else {
                            // 챌린지 정보가 없을 때
                            VStack(spacing: 16) {
                                Text("챌린지 정보를 불러올 수 없습니다")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray600)
                                
                                Button(action: {
                                    viewModel.showChallengeInfo = false
                                    dismiss()
                                }) {
                                    Text("돌아가기")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.gray400)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(40)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .loadingOverlay(isLoading: $viewModel.isLoading)
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .onChange(of: viewModel.startSuccess) { success in
            // 성공 시에만 화면 이동
            if let success = success, success {
                dismiss()
            }
        }
    }
}

