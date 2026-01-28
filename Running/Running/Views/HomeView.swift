//
//  HomeView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI
import Charts

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("안녕하세요, \(viewModel.currentUser?.name ?? "러너")님! 👋")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("오늘도 멋진 러닝을 시작해보세요")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Points Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("보유 포인트")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack(spacing: 8) {
                                Image(systemName: "bitcoinsign.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                
                                Text("\(viewModel.currentUser?.point ?? 0)P")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Button("사용하기") {
                            // Shop 화면으로 이동
                            appState.selectedTab = .shop
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.emerald500)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
                .padding(24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gradientStart, Color.gradientEnd]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Daily Login Reward
                if !viewModel.loginRewardClaimed && viewModel.currentUser != nil {
                    DailyLoginRewardCard {
                        viewModel.claimLoginReward()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, -16)
                    .padding(.bottom, 16)
                }
                
                // Stats Tabs
                VStack(spacing: 16) {
                    // Tab Selector
                    HStack(spacing: 0) {
                        ForEach(HomeViewModel.StatsTab.allCases, id: \.self) { tab in
                            Button(action: {
                                viewModel.selectedTab = tab
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(
                                        viewModel.selectedTab == tab ? .gray900 : .gray600
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        viewModel.selectedTab == tab ? Color.white : Color.clear
                                    )
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.gray100)
                    .cornerRadius(12)
                    
                    // Tab Content
                    Group {
                        switch viewModel.selectedTab {
                        case .daily:
                            if let stats = viewModel.dailyStats {
                                DailyStatsView(stats: stats, viewModel: viewModel)
                            } else {
                                ProgressView()
                                    .frame(height: 200)
                            }
                        case .weekly:
                            if let stats = viewModel.weeklyStats {
                                WeeklyStatsView(stats: stats)
                            } else {
                                ProgressView()
                                    .frame(height: 200)
                            }
                        case .monthly:
                            if let stats = viewModel.monthlyStats {
                                MonthlyStatsView(stats: stats)
                            } else {
                                ProgressView()
                                    .frame(height: 200)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, viewModel.loginRewardClaimed || viewModel.currentUser == nil ? 24 : 16)
                
                // Achievement Section (미션이 있을 때만 표시)
                if !viewModel.achievements.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                            
                            Text("이번 주 달성")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.gray900)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.achievements, id: \.id) { achievement in
                                AchievementRow(achievement: achievement)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 80) // 하단 바 공간 확보
                }
            }
        }
        .background(Color.gray50)
        .loadingOverlay(isLoading: $viewModel.isLoading)
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .onAppear {
            // AppState의 사용자 정보를 ViewModel에 전달
            viewModel.currentUserUuid = appState.currentUser?.uuid
            viewModel.currentUser = appState.currentUser
            // 사용자 정보가 없으면 로드
            if appState.currentUser == nil {
                viewModel.loadUser()
            } else {
                viewModel.loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ActivityCompleted"))) { _ in
            // 러닝 완료 후 홈 화면 통계 새로고침
            viewModel.loadData()
            // 사용자 정보도 새로고침 (포인트 업데이트를 위해)
            viewModel.loadUser()
        }
        .onChange(of: appState.selectedTab) { newTab in
            // 홈 탭으로 전환될 때 새로고침
            if newTab == .home {
                viewModel.currentUserUuid = appState.currentUser?.uuid
                viewModel.currentUser = appState.currentUser
                viewModel.loadData()
            }
        }
    }
}

struct DailyLoginRewardCard: View {
    let action: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("출석 보상")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("오늘의 포인트를 받아가세요!")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            Spacer()
            
            Button(action: action) {
                Text("+10P")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.orange500)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange400, Color.orange500]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct DailyStatsView: View {
    let stats: DailyStats
    let viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("오늘의 활동")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.gray900)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "거리",
                    value: "\(String(format: "%.1f", stats.distance))km",
                    color: Color.emerald500,
                    backgroundColor: Color.emerald50
                )
                
                StatCard(
                    title: "시간",
                    value: viewModel.formatTime(stats.time),
                    color: Color.blue500,
                    backgroundColor: Color.blue50
                )
                
                StatCard(
                    title: "칼로리",
                    value: "\(stats.calories)",
                    color: Color.purple,
                    backgroundColor: Color.purple.opacity(0.1)
                )
                
                StatCard(
                    title: "포인트",
                    value: "+\(stats.points)P",
                    color: Color.orange500,
                    backgroundColor: Color.orange50
                )
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct WeeklyStatsView: View {
    let stats: WeeklyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("주간 통계")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.gray900)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("총 거리")
                    .font(.system(size: 12))
                    .foregroundColor(.gray500)
                
                Text("\(String(format: "%.1f", stats.totalDistance))km")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.emerald500)
            }
            .padding(.bottom, 16)
            
            // Simple bar chart representation
            VStack(spacing: 8) {
                ForEach(stats.dailyData, id: \.day) { data in
                    HStack {
                        Text(data.day)
                            .font(.system(size: 12))
                            .foregroundColor(.gray600)
                            .frame(width: 30, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray100)
                                    .frame(height: 20)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.emerald500)
                                    .frame(width: geometry.size.width * CGFloat(data.distance / 7.2), height: 20)
                            }
                        }
                        .frame(height: 20)
                        
                        Text("\(String(format: "%.1f", data.distance))km")
                            .font(.system(size: 12))
                            .foregroundColor(.gray600)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct MonthlyStatsView: View {
    let stats: MonthlyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("월간 통계")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.gray900)
            
            HStack(spacing: 16) {
                VStack {
                    Text("\(String(format: "%.1f", stats.totalDistance))km")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.emerald500)
                    
                    Text("총 거리")
                        .font(.system(size: 10))
                        .foregroundColor(.gray500)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(stats.runningCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.blue500)
                    
                    Text("러닝 횟수")
                        .font(.system(size: 10))
                        .foregroundColor(.gray500)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("\(stats.earnedPoints)P")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.orange500)
                    
                    Text("획득 포인트")
                        .font(.system(size: 10))
                        .foregroundColor(.gray500)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 16)
            
            // Simple line chart representation
            VStack(spacing: 8) {
                ForEach(stats.weeklyData, id: \.week) { data in
                    HStack {
                        Text(data.week)
                            .font(.system(size: 12))
                            .foregroundColor(.gray600)
                            .frame(width: 60, alignment: .leading)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray100)
                                    .frame(height: 20)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.emerald500)
                                    .frame(width: geometry.size.width * CGFloat(data.distance / 24.1), height: 20)
                            }
                        }
                        .frame(height: 20)
                        
                        Text("\(String(format: "%.1f", data.distance))km")
                            .font(.system(size: 12))
                            .foregroundColor(.gray600)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(color.opacity(0.8))
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    // 남은 일수 계산
    var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        let missionDuration: Int = achievement.term == .week ? 7 : 30
        let endDate = calendar.date(byAdding: .day, value: missionDuration, to: achievement.createdAt) ?? achievement.createdAt
        let days = calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
        return max(0, days)
    }
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(achievement.isCompleted ? Color.emerald500 : Color.gray400)
                    .frame(width: 40, height: 40)
                
                if achievement.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "figure.run")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(achievement.isCompleted ? .gray900 : .gray600)
                    
                    // 미션 기간 표시
                    Text(achievement.term == .week ? "주간" : "월간")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            achievement.term == .week ? Color.blue500 : Color.purple500
                        )
                        .cornerRadius(4)
                }
                
                Text(achievement.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray500)
                
                // 남은 일수 표시
                if !achievement.isCompleted && achievement.status == .inProgress {
                    Text("\(daysRemaining)일 남음")
                        .font(.system(size: 10))
                        .foregroundColor(daysRemaining <= 3 ? Color.red500 : Color.gray500)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // 서버 상태를 그대로 표시
                Text(achievement.status.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(
                        achievement.status == .completed ? Color.orange500 :
                        achievement.status == .inProgress ? Color.emerald500 : Color.gray400
                    )
                
                // 완료된 경우에만 포인트 표시
                if achievement.isCompleted {
                    Text("+\(achievement.rewardPoints)P")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.orange500)
                }
            }
        }
        .padding(12)
        .background(achievement.isCompleted ? Color.emerald50 : Color.gray50)
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}

