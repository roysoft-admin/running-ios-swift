//
//  RunningInProgressView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct RunningInProgressView: View {
    @ObservedObject var viewModel: RunViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showEndDialog = false
    @State private var showFullScreenMap = false
    @State private var showReportDetail = false
    @State private var completedActivityUuid: String?
    
    var body: some View {
        ZStack {
            Color.gray50.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Map Area
                ZStack {
                    if !viewModel.routes.isEmpty {
                        ActivityMapView(routes: viewModel.routes, isInteractive: true)
                            .ignoresSafeArea()
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.emerald100, Color.blue50]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 128))
                                .foregroundColor(.gray400.opacity(0.5))
                            
                            Text("실시간 경로 추적 중...")
                                .font(.system(size: 14))
                                .foregroundColor(.gray400)
                        }
                    }
                    
                    VStack {
                        HStack {
                            // Status Indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(viewModel.isPaused ? Color.orange500 : Color.emerald500)
                                    .frame(width: 12, height: 12)
                                    .opacity(viewModel.isPaused ? 1.0 : 0.7)
                                    .animation(
                                        Animation.easeInOut(duration: 1.0)
                                            .repeatForever(autoreverses: true),
                                        value: viewModel.isPaused
                                    )
                                
                                Text(viewModel.isPaused ? "일시정지" : "러닝 중")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray900)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .padding()
                            
                            Spacer()
                            
                            Button(action: {
                                showFullScreenMap = true
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
                
                // Stats & Controls
                VStack(spacing: 24) {
                    // Main Distance Display
                    VStack(spacing: 8) {
                        Text("거리")
                            .font(.system(size: 14))
                            .foregroundColor(.gray500)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(String(format: "%.2f", viewModel.distance))
                                .font(.system(size: 64, weight: .bold))
                                .foregroundColor(Color.emerald500)
                            
                            Text("km")
                                .font(.system(size: 24))
                                .foregroundColor(.gray500)
                        }
                    }
                    .padding(.top, 24)
                    
                    // Secondary Stats
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("시간")
                                .font(.system(size: 10))
                                .foregroundColor(.gray500)
                            
                            Text(viewModel.formatTime(viewModel.time))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.gray900)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Text("페이스")
                                .font(.system(size: 10))
                                .foregroundColor(.gray500)
                            
                            Text(viewModel.formatPace(viewModel.pace))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.gray900)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Text("칼로리")
                                .font(.system(size: 10))
                                .foregroundColor(.gray500)
                            
                            Text("\(viewModel.calories)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.gray900)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Control Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            if viewModel.isPaused {
                                viewModel.resumeRunning()
                            } else {
                                viewModel.pauseRunning()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 24))
                                
                                Text(viewModel.isPaused ? "재개" : "일시정지")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(viewModel.isPaused ? Color.emerald500 : Color.orange500)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        
                        Button(action: {
                            showEndDialog = true
                        }) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.red)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    // Safety Message
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.blue500)
                        
                        Text("🚦 안전한 러닝을 위해 주변을 항상 확인하세요")
                            .font(.system(size: 12))
                            .foregroundColor(Color.blue500)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue200, lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(24, corners: [.topLeft, .topRight])
            }
        }
        .onAppear {
            // 이미 startRunning이 호출되었으므로 여기서는 호출하지 않음
            // viewModel.startRunning은 RunModeSelectionView에서 이미 호출됨
        }
        .alert("러닝을 종료하시겠어요?", isPresented: $showEndDialog) {
            Button("계속하기", role: .cancel) {}
            Button("종료하기", role: .destructive) {
                viewModel.stopRunning()
                // dismiss()는 리포트 상세 화면으로 이동 후에 호출됨
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text("거리: \(String(format: "%.2f", viewModel.distance))km")
                Text("시간: \(viewModel.formatTime(viewModel.time))")
                Text("칼로리: \(viewModel.calories)kcal")
            }
        }
        .fullScreenCover(isPresented: $showFullScreenMap) {
            FullScreenMapView(routes: viewModel.routes)
        }
        .fullScreenCover(isPresented: $showReportDetail) {
            if let activityUuid = completedActivityUuid {
                NavigationView {
                    ReportDetailView(activityUuid: activityUuid, showBackButton: true)
                        .onDisappear {
                            // 리포트 상세 화면이 닫힐 때 러닝 화면도 닫기
                            dismiss()
                        }
                }
            }
        }
        .onChange(of: viewModel.completedActivityUuid) { newValue in
            if let uuid = newValue {
                completedActivityUuid = uuid
                // 리포트 상세 화면 표시
                showReportDetail = true
                // 리포트 화면 새로고침을 위한 알림 전송
                NotificationCenter.default.post(name: NSNotification.Name("ActivityCompleted"), object: nil)
            }
        }
    }
}

struct FullScreenMapView: View {
    let routes: [ActivityRoute]
    @Environment(\.dismiss) var dismiss
    @State private var isPresented = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ActivityMapView(routes: routes, isInteractive: true)
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

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension Color {
    static let blue200 = Color(red: 0.8, green: 0.9, blue: 1.0)
}

#Preview {
    RunningInProgressView(viewModel: RunViewModel())
}

