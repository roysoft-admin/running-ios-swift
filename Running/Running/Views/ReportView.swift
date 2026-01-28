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
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.formatDate(viewModel.getActivityDate(record)))
                        .font(.system(size: 12))
                        .foregroundColor(.gray500)
                    
                    Text("\(String(format: "%.1f", record.distance))km")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray900)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(record.type.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.emerald500)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.emerald50)
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
                    Text("시간")
                        .font(.system(size: 10))
                        .foregroundColor(.gray500)
                    
                    Text(viewModel.formatTime(record.time))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray900)
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
        .background(Color.white)
        .cornerRadius(16)
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
                ScrollView {
                    VStack(spacing: 24) {
                        // Record Summary
                        VStack(spacing: 16) {
                            Text(viewModel.formatDate(viewModel.getActivityDate(record)))
                                .font(.system(size: 16))
                                .foregroundColor(.gray500)
                            
                            Text("\(String(format: "%.1f", record.distance))km")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(Color.emerald500)
                            
                            Text(record.type.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.emerald500)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.emerald50)
                                .cornerRadius(16)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(16)
                        
                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatBox(title: "시간", value: viewModel.formatTime(record.time), unit: "")
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
                    }
                    .padding(.vertical, 16)
                }
                .background(Color.gray50)
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray400)
                    
                    Text("데이터를 불러올 수 없습니다")
                        .font(.system(size: 16))
                        .foregroundColor(.gray500)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
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
        .onAppear {
            viewModel.loadActivityDetail(activityUuid: activityUuid) { loadedActivity in
                activity = loadedActivity
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationView {
        ReportView()
    }
}

