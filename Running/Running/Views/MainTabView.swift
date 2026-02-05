//
//  MainTabView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI
import Combine

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var runViewModel = RunViewModel()
    @State private var showRunningInProgress = false
    @State private var hasCheckedActiveActivity = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .run:
                    RunView()
                        .environmentObject(runViewModel)
                case .report:
                    NavigationView {
                        ReportView()
                    }
                case .home:
                    NavigationView {
                        HomeView()
                    }
                case .shop:
                    ShopView()
                case .myPage:
                    NavigationView {
                        MyPageView()
                    }
                }
            }
            
            VStack {
                Spacer()
                
                BottomNavView(selectedTab: $appState.selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $showRunningInProgress) {
            RunningInProgressView(viewModel: runViewModel)
        }
        .onAppear {
            // 메인 화면 진입 시 한 번만 체크
            if !hasCheckedActiveActivity, let userUuid = appState.currentUser?.uuid {
                hasCheckedActiveActivity = true
                checkActiveActivity(userUuid: userUuid)
            }
        }
    }
    
    private func checkActiveActivity(userUuid: String) {
        print("[MainTabView] 🔵 진행 중인 활동 체크 시작")
        let activityService = ActivityService.shared
        
        activityService.getActiveActivity(userUuid: userUuid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // 404 에러는 진행 중인 활동이 없다는 의미이므로 무시
                        if let networkError = error as? NetworkError,
                           case .serverError(let code, _) = networkError,
                           code == 404 {
                            print("[MainTabView] ✅ 진행 중인 활동 없음")
                        } else {
                            print("[MainTabView] ❌ 진행 중인 활동 조회 실패: \(error)")
                        }
                    }
                },
                receiveValue: { [weak runViewModel] response in
                    guard let runViewModel = runViewModel else { return }
                    let activity = response.activity
                    print("[MainTabView] ✅ 진행 중인 활동 발견: UUID=\(activity.uuid)")
                    
                    // RunViewModel에 activity 정보 설정
                    runViewModel.currentActivityUuid = activity.uuid
                    runViewModel.currentUserUuid = userUuid
                    
                    // 챌린지 정보가 있으면 로드
                    if let challenge = activity.challenge {
                        runViewModel.currentChallenge = challenge
                        runViewModel.currentChallengeUuid = challenge.uuid
                        print("[MainTabView] ✅ 챌린지 정보 로드: UUID=\(challenge.uuid)")
                    } else if let challengeId = activity.challengeId {
                        // challenge 정보가 없으면 challengeId만 저장
                        runViewModel.currentChallengeUuid = String(challengeId)
                        runViewModel.currentChallenge = nil
                    } else {
                        // 일반 러닝이므로 챌린지 정보 초기화
                        runViewModel.currentChallenge = nil
                        runViewModel.currentChallengeUuid = nil
                        print("[MainTabView] 🔵 일반 러닝 복원: 챌린지 정보 초기화")
                    }
                    
                    // 러닝 상태 복원
                    runViewModel.restoreRunningState(startTime: activity.startTime)
                    
                    // 기존 거리 복원 (routes가 있으면)
                    if let routes = activity.routes, !routes.isEmpty {
                        runViewModel.routes = routes
                        // 거리 계산
                        var totalDistance: Double = 0
                        for i in 1..<routes.count {
                            let prev = routes[i-1]
                            let curr = routes[i]
                            let distance = runViewModel.calculateDistance(
                                lat1: prev.lat,
                                long1: prev.long,
                                lat2: curr.lat,
                                long2: curr.long
                            )
                            totalDistance += distance / 1000.0 // km로 변환
                        }
                        runViewModel.distance = totalDistance
                    }
                    
                    // 러닝 화면으로 자동 이동
                    showRunningInProgress = true
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    MainTabView()
}


