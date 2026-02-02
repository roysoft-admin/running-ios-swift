//
//  ReportView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct ReportView: View {
    @StateObject private var viewModel = ReportViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("러닝 기록")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray900)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.white)
                
                // Month Selector
                HStack {
                    Button(action: {
                        viewModel.previousMonth()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.gray700)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 20))
                            .foregroundColor(Color.emerald500)
                        
                        Text(viewModel.formatMonth(viewModel.currentMonth))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray900)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.nextMonth()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20))
                            .foregroundColor(.gray700)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray200),
                    alignment: .bottom
                )
                
                // Stats Summary
                HStack(spacing: 16) {
                    VStack {
                        Text("\(viewModel.monthlyStats.totalRuns)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.emerald500)
                        
                        Text("총 러닝")
                            .font(.system(size: 10))
                            .foregroundColor(.gray500)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("\(String(format: "%.1f", viewModel.monthlyStats.totalDistance))km")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.emerald500)
                        
                        Text("총 거리")
                            .font(.system(size: 10))
                            .foregroundColor(.gray500)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("\(viewModel.monthlyStats.totalPoints)P")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.orange500)
                        
                        Text("획득 포인트")
                            .font(.system(size: 10))
                            .foregroundColor(.gray500)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .background(Color.white)
                
                // Report List
                VStack(spacing: 12) {
                    ForEach(viewModel.reports) { activity in
                        NavigationLink(destination: ReportDetailView(activityUuid: activity.uuid)) {
                            ReportRow(record: activity, viewModel: viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Ad Banner
                Text("광고 영역")
                    .font(.system(size: 12))
                    .foregroundColor(.gray500)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.gray100)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 80) // 하단 바 공간 확보
            }
        }
        .background(Color.gray50)
        .loadingOverlay(isLoading: $viewModel.isLoading)
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .onAppear {
            // AppState의 사용자 정보를 ViewModel에 전달
            viewModel.currentUserUuid = appState.currentUser?.uuid
            viewModel.loadReports()
        }
        .onChange(of: appState.selectedTab) { newTab in
            // 리포트 탭으로 전환될 때 새로고침
            if newTab == .report {
                viewModel.loadReports()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ActivityCompleted"))) { _ in
            // 러닝 종료 후 리포트 목록 새로고침
            viewModel.loadReports()
        }
    }
}

struct ReportRow: View {
    let record: Activity
    let viewModel: ReportViewModel
    
    var body: some View {
        let isChallenge = record.challengeId != nil
        
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.formatDate(viewModel.getActivityDate(record)))
                        .font(.system(size: 12))
                        .foregroundColor(.gray500)
                    
                    Text("\(String(format: "%.1f", record.distance))km")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isChallenge ? Color.blue500 : .gray900)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(isChallenge ? "AI 챌린지" : record.type.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isChallenge ? Color.blue500 : Color.emerald500)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isChallenge ? Color.blue50 : Color.emerald50)
                        .cornerRadius(12)
                    
                    if record.points > 0 {
                        Text("+\(record.points)P")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.orange500)
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("전체 시간")
                        .font(.system(size: 10))
                        .foregroundColor(.gray500)
                    
                    Text(viewModel.formatTime(record.time))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray900)
                    
                    Text("실제 러닝")
                        .font(.system(size: 8))
                        .foregroundColor(.gray400)
                    
                    Text(viewModel.formatTime(record.actualRunningTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.emerald500)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("페이스")
                        .font(.system(size: 10))
                        .foregroundColor(.gray500)
                    
                    Text(viewModel.formatPace(record.pace))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray900)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("칼로리")
                        .font(.system(size: 10))
                        .foregroundColor(.gray500)
                    
                    Text("\(record.calories ?? 0)kcal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray900)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            Group {
                if isChallenge {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue50.opacity(0.5), Color.purple500.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    Color.white
                }
            }
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isChallenge ? Color.blue500.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct ReportDetailView: View {
    let activityUuid: String
    var showBackButton: Bool = false // fullScreenCover로 표시될 때만 true
    @StateObject private var viewModel = ReportViewModel()
    @State private var activity: Activity?
    @State private var isLoading: Bool = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let record = activity {
                reportDetailContent(record: record)
            } else {
                Text("활동 정보를 불러올 수 없습니다.")
                    .foregroundColor(.gray500)
            }
        }
        .task(id: activityUuid) {
            // AOS의 LaunchedEffect(activityUuid)와 동일하게 activityUuid가 변경될 때만 로드
            print("[ReportDetailView] 🔵 task 시작: activityUuid=\(activityUuid)")
            isLoading = true
            activity = nil
            
            viewModel.loadActivityDetail(activityUuid: activityUuid) { loadedActivity in
                print("[ReportDetailView] 📥 loadActivityDetail completion: loadedActivity=\(loadedActivity?.uuid ?? "nil")")
                DispatchQueue.main.async {
                    activity = loadedActivity
                    isLoading = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func backgroundGradient(isChallenge: Bool) -> some View {
        if isChallenge {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue50, Color.purple500.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.white
        }
    }
    
    @ViewBuilder
    private func scrollViewBackground(isChallenge: Bool) -> some View {
        if isChallenge {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue50.opacity(0.3), Color.purple500.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.gray50
        }
    }
    
    @ViewBuilder
    private func reportDetailContent(record: Activity) -> some View {
        let isChallenge = record.challengeId != nil
        
        ScrollView {
                    VStack(spacing: 24) {
                        // Record Summary
                        VStack(spacing: 16) {
                            Text(viewModel.formatDate(viewModel.getActivityDate(record)))
                                .font(.system(size: 16))
                                .foregroundColor(.gray500)
                            
                            Text("\(String(format: "%.1f", record.distance))km")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(isChallenge ? Color.blue500 : Color.emerald500)
                            
                            HStack(spacing: 8) {
                                Text(isChallenge ? "AI 챌린지" : record.type.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(isChallenge ? Color.blue500 : Color.emerald500)
                                
                                // 챌린지 성공 여부 표시
                                if isChallenge, let challengeStatus = record.challengeStatus {
                                    if challengeStatus == .success {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                            Text("성공")
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                    } else if challengeStatus == .failed {
                                        HStack(spacing: 4) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 12))
                                            Text("실패")
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isChallenge ? Color.blue50 : Color.emerald50)
                            .cornerRadius(16)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(backgroundGradient(isChallenge: isChallenge))
                        .cornerRadius(16)
                        
                        // 챌린지 목표 정보 표시
                        if isChallenge, let challenge = record.challenge {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "target")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue500)
                                    
                                    Text("챌린지 목표")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray500)
                                }
                                
                                HStack(spacing: 24) {
                                    if let targetDistance = challenge.targetDistance {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("거리")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray500)
                                            
                                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                                Text(String(format: "%.1f", targetDistance))
                                                    .font(.system(size: 28, weight: .bold))
                                                    .foregroundColor(.blue500)
                                                Text("km")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.gray600)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    if let targetTime = challenge.targetTime {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("시간")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray500)
                                            
                                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                                Text("\(targetTime)")
                                                    .font(.system(size: 28, weight: .bold))
                                                    .foregroundColor(.purple500)
                                                Text("분")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.gray600)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.gray50)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                            
                            // 챌린지 성공 시 포인트 지급 표시
                            if let challengeStatus = record.challengeStatus, challengeStatus == .success {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.orange500)
                                    
                                    Text("챌린지 완료 포인트 지급 완료")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray700)
                                    
                                    Spacer()
                                    
                                    Text("+30P")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.orange500)
                                }
                                .padding(16)
                                .background(Color.orange50)
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("전체 시간")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray500)
                                
                                Text(viewModel.formatTime(record.time))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.gray900)
                                
                                Text("실제 러닝: \(viewModel.formatTime(record.actualRunningTime))")
                                    .font(.system(size: 10))
                                    .foregroundColor(.emerald500)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.gray50)
                            .cornerRadius(16)
                            
                            StatBox(title: "페이스", value: viewModel.formatPace(record.pace), unit: "")
                            StatBox(title: "칼로리", value: "\(record.calories ?? 0)", unit: "kcal")
                            StatBox(title: "포인트", value: "+\(record.points)", unit: "P")
                        }
                        .padding(.horizontal, 16)
                        
                        // Map View
                        if let routes = record.routes, !routes.isEmpty {
                            ActivityMapView(routes: routes, isInteractive: true)
                                .frame(height: 300)
                                .cornerRadius(16)
                                .padding(.horizontal, 16)
                        } else {
                            VStack {
                                Image(systemName: "map")
                                    .font(.system(size: 64))
                                    .foregroundColor(.gray400)
                                
                                Text("경로 데이터가 없습니다")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray500)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.gray100)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                        }
                        
                        // Share Button
                        // TODO: Implement sharing (max 4 shares per day, 5 points per share)
                        Button(action: {
                            // TODO: Share activity - pointUuid는 PointPolicy에서 가져와야 함
                            // 임시로 빈 문자열 전달 (실제로는 Point 목록에서 "러닝 공유" Point의 uuid를 찾아야 함)
                            viewModel.shareActivity(activityUuid: activityUuid, pointUuid: "")
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("공유하기")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.emerald500)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 60) // 하단 탭바 높이만큼 공간 확보
                    }
                    .padding(.vertical, 16)
                }
                .background(scrollViewBackground(isChallenge: isChallenge))
                .navigationTitle("러닝 상세")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if showBackButton {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                dismiss()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("뒤로")
                                }
                                .foregroundColor(.emerald500)
                            }
                        }
                    }
                }
    }
}

#Preview {
    NavigationView {
        ReportView()
    }
}

