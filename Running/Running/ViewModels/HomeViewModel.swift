//
//  HomeViewModel.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var currentPoints: Int = 0
    @Published var loginRewardClaimed: Bool = false
    @Published var selectedTab: StatsTab = .daily
    @Published var dailyStats: DailyStats?
    @Published var weeklyStats: WeeklyStats?
    @Published var monthlyStats: MonthlyStats?
    @Published var achievements: [Achievement] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    enum StatsTab: String, CaseIterable {
        case daily = "오늘"
        case weekly = "주간"
        case monthly = "월간"
    }
    
    private let activityService = ActivityService.shared
    private let missionService = MissionService.shared
    private let userService = UserService.shared
    private let pointService = PointService.shared
    private let pointViewModel = PointViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // 출석 보상 Point UUID (동적으로 가져옴)
    @Published var dailyLoginPointUuid: String?
    
    // Point 목록 (Activity의 pointId로 포인트 금액 조회용)
    private var points: [Point] = []
    
    // TODO: Get current user UUID from app state
    var currentUserUuid: String?
    
    init() {
        loadData()
    }
    
    func loadData() {
        loadUser()
        loadPoints()  // Point 목록 로드 후 출석 보상 체크
        loadDailyStats()
        loadWeeklyStats()
        loadMonthlyStats()
        loadMissions()
    }
    
    /// Point 목록을 로드하고 출석 보상 Point ID를 찾아서 저장
    func loadPoints() {
        print("[HomeViewModel] 🔵 Point 목록 로드 시작")
        
        pointService.getPoints()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("[HomeViewModel] ❌ Point 목록 로드 실패: \(error)")
                        // 에러가 발생해도 계속 진행
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    print("[HomeViewModel] 📥 Point 목록 로드 성공: \(response.points.count)개")
                    
                    // Point 목록 저장 (Activity의 pointId로 포인트 금액 조회용)
                    self.points = response.points
                    
                    // "출석 보상" Point 찾기
                    if let dailyLoginPoint = response.points.first(where: { $0.title == "출석 보상" || $0.title.contains("출석") }) {
                        self.dailyLoginPointUuid = dailyLoginPoint.uuid
                        print("[HomeViewModel] ✅ 출석 보상 Point 찾음: UUID=\(dailyLoginPoint.uuid), 포인트=\(dailyLoginPoint.point)")
                        
                        // 출석 보상 체크 및 자동 제공
                        self.checkAndClaimDailyLoginReward()
                    } else {
                        print("[HomeViewModel] ⚠️ 출석 보상 Point를 찾을 수 없습니다")
                        self.checkAndClaimDailyLoginReward()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadUser() {
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else {
            errorMessage = "사용자 정보를 찾을 수 없습니다"
            return
        }
        
        userService.getUser(userUuid: userUuid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.currentUser = response.user
                    self?.currentPoints = response.user.point
                    self?.currentUserUuid = response.user.uuid
                }
            )
            .store(in: &cancellables)
    }
    
    func loadDailyStats() {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else { return }
        
        activityService.getActivities(
            startDate: startOfDay,
            endDate: endOfDay,
            userUuid: userUuid
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                let allActivities = response.activities
                
                // 완료된 활동만 필터링 (distance > 0이고 endTime이 startTime보다 큰 활동)
                let completedActivities = allActivities.filter { activity in
                    activity.distance > 0 && activity.endTime > activity.startTime
                }
                
                let totalDistance = completedActivities.reduce(0) { $0 + $1.distance }
                let totalTime = completedActivities.reduce(0) { $0 + $1.time }
                let totalCalories = completedActivities.reduce(0) { $0 + ($1.calories ?? 0) }
                
                // Activity의 pointId로 포인트 금액 계산
                // pointId는 Int이지만, Point를 찾을 때는 id로 찾고 uuid는 API 호출 시 사용
                let totalPoints = completedActivities.reduce(0) { sum, activity in
                    if let pointId = activity.pointId,
                       let point = self.points.first(where: { $0.id == pointId }) {
                        return sum + point.point
                    }
                    return sum
                }
                
                self.dailyStats = DailyStats(
                    distance: totalDistance,
                    time: totalTime,
                    calories: totalCalories,
                    points: totalPoints
                )
            }
        )
        .store(in: &cancellables)
    }
    
    func loadWeeklyStats() {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else { return }
        
        activityService.getActivities(
            startDate: startOfWeek,
            endDate: endOfWeek,
            userUuid: userUuid
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                }
            },
            receiveValue: { [weak self] response in
                let allActivities = response.activities
                
                // 완료된 활동만 필터링 (distance > 0이고 endTime이 startTime보다 큰 활동)
                let completedActivities = allActivities.filter { activity in
                    activity.distance > 0 && activity.endTime > activity.startTime
                }
                
                let totalDistance = completedActivities.reduce(0) { $0 + $1.distance }
                
                // Group by day
                let dayNames = ["일", "월", "화", "수", "목", "금", "토"]
                var dailyData: [DailyData] = []
                
                for i in 0..<7 {
                    let date = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
                    let dayActivities = completedActivities.filter { activity in
                        calendar.isDate(activity.startTime, inSameDayAs: date)
                    }
                    let dayDistance = dayActivities.reduce(0) { $0 + $1.distance }
                    
                    dailyData.append(DailyData(
                        day: dayNames[calendar.component(.weekday, from: date) - 1],
                        distance: dayDistance
                    ))
                }
                
                self?.weeklyStats = WeeklyStats(
                    totalDistance: totalDistance,
                    runningCount: completedActivities.count,
                    dailyData: dailyData
                )
            }
        )
        .store(in: &cancellables)
    }
    
    func loadMonthlyStats() {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else { return }
        
        activityService.getActivities(
            startDate: startOfMonth,
            endDate: endOfMonth,
            userUuid: userUuid
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                let allActivities = response.activities
                
                // 완료된 활동만 필터링 (distance > 0이고 endTime이 startTime보다 큰 활동)
                let completedActivities = allActivities.filter { activity in
                    activity.distance > 0 && activity.endTime > activity.startTime
                }
                
                let totalDistance = completedActivities.reduce(0) { $0 + $1.distance }
                
                // Activity의 pointId로 포인트 금액 계산
                // pointId는 Int이지만, Point를 찾을 때는 id로 찾고 uuid는 API 호출 시 사용
                let totalPoints = completedActivities.reduce(0) { sum, activity in
                    if let pointId = activity.pointId,
                       let point = self.points.first(where: { $0.id == pointId }) {
                        return sum + point.point
                    }
                    return sum
                }
                
                // Group by week
                var weeklyData: [WeeklyData] = []
                var currentWeekStart = startOfMonth
                var weekNumber = 1
                
                while currentWeekStart <= endOfMonth {
                    let weekEnd = min(calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!, endOfMonth)
                    let weekActivities = completedActivities.filter { activity in
                        activity.startTime >= currentWeekStart && activity.startTime <= weekEnd
                    }
                    let weekDistance = weekActivities.reduce(0) { $0 + $1.distance }
                    
                    weeklyData.append(WeeklyData(
                        week: "Week \(weekNumber)",
                        distance: weekDistance
                    ))
                    
                    currentWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart)!
                    weekNumber += 1
                }
                
                self.monthlyStats = MonthlyStats(
                    totalDistance: totalDistance,
                    runningCount: completedActivities.count,
                    earnedPoints: totalPoints,
                    weeklyData: weeklyData
                )
            }
        )
        .store(in: &cancellables)
    }
    
    func loadMissions() {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else { return }
        
        missionService.getUserMissions(
            userUuid: userUuid,
            startDate: startOfWeek,
            endDate: endOfWeek
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                }
            },
            receiveValue: { [weak self] response in
                self?.achievements = response.userMissions.compactMap { userMission in
                    guard let mission = userMission.mission else { return nil }
                    
                    let progress = Double(userMission.userValue)
                    let target = Double(mission.targetValue)
                    let isCompleted = userMission.status == .completed
                    
                    return Achievement(
                        id: String(userMission.id),
                        title: mission.title,
                        description: "\(userMission.userValue)/\(mission.targetValue)",
                        progress: progress,
                        target: target,
                        isCompleted: isCompleted,
                        rewardPoints: mission.point
                    )
                }
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Daily Login Reward Check & Claim
    
    /// 출석 보상을 받았는지 체크하고, 받지 않았으면 자동으로 제공
    func checkAndClaimDailyLoginReward() {
        // 출석 보상 Point UUID가 아직 로드되지 않았으면 대기
        guard let pointUuid = dailyLoginPointUuid else {
            print("[HomeViewModel] ⏳ 출석 보상 Point UUID가 아직 로드되지 않았습니다")
            return
        }
        
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else {
            print("[HomeViewModel] ⚠️ 사용자 UUID를 찾을 수 없습니다")
            return
        }
        
        print("[HomeViewModel] 🔵 출석 보상 체크 시작 (Point UUID: \(pointUuid))")
        
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // 오늘 날짜로 출석 보상 포인트를 받았는지 확인
        pointService.getUserPoints(
            startDate: startOfDay,
            endDate: endOfDay,
            pointUuid: pointUuid,
            pointType: .earned
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("[HomeViewModel] ❌ 출석 보상 체크 실패: \(error)")
                    // 에러가 발생해도 계속 진행 (출석 보상은 선택 사항)
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // 오늘 출석 보상을 받았는지 확인
                let hasReceivedToday = !response.userPoints.isEmpty
                print("[HomeViewModel] 📥 출석 보상 체크 결과: \(hasReceivedToday ? "이미 받음" : "받지 않음")")
                
                if hasReceivedToday {
                    self.loginRewardClaimed = true
                    print("[HomeViewModel] ✅ 오늘 출석 보상을 이미 받았습니다 - 출석 버튼 숨김")
                } else {
                    // 출석 보상을 받지 않았으면 자동으로 제공
                    print("[HomeViewModel] 🔵 출석 보상 자동 제공 시작 (자동 클릭)")
                    self.claimDailyLoginReward()
                }
            }
        )
        .store(in: &cancellables)
    }
    
    /// 출석 보상 제공
    func claimDailyLoginReward() {
        guard !loginRewardClaimed else {
            print("[HomeViewModel] ⚠️ 이미 출석 보상을 받았습니다")
            return
        }
        
        // 출석 보상 Point UUID가 아직 로드되지 않았으면 대기
        guard let pointUuid = dailyLoginPointUuid else {
            print("[HomeViewModel] ⏳ 출석 보상 Point UUID가 아직 로드되지 않았습니다")
            return
        }
        
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else {
            print("[HomeViewModel] ⚠️ 사용자 UUID를 찾을 수 없습니다")
            return
        }
        
        print("[HomeViewModel] 🔵 출석 보상 제공 시작 (Point UUID: \(pointUuid))")
        
        // Point 목록에서 출석 보상 포인트 금액 가져오기
        // 먼저 Point 목록을 다시 가져와서 포인트 금액 확인
        pointService.getPoints()
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] response -> AnyPublisher<UserPointResponseDTO, NetworkError> in
                guard let self = self else {
                    return Fail(error: NetworkError.unknown)
                        .eraseToAnyPublisher()
                }
                
                // 출석 보상 Point 찾기
                guard let dailyLoginPoint = response.points.first(where: { $0.uuid == pointUuid }) else {
                    print("[HomeViewModel] ❌ 출석 보상 Point를 찾을 수 없습니다 (UUID: \(pointUuid))")
                    return Fail(error: NetworkError.unknown)
                        .eraseToAnyPublisher()
                }
                
                let pointAmount = dailyLoginPoint.point
                print("[HomeViewModel] 📥 출석 보상 포인트 금액: \(pointAmount)")
                
                // 출석 보상 제공
                return self.pointService.createUserPoint(
                    userUuid: userUuid,
                    pointUuid: pointUuid,
                    point: pointAmount,
                    referenceUuid: nil
                )
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("[HomeViewModel] ❌ 출석 보상 제공 실패: \(error)")
                        self?.errorMessage = "출석 보상 제공에 실패했습니다: \(error.errorDescription ?? "알 수 없는 오류")"
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    print("[HomeViewModel] ✅ 출석 보상 제공 성공 - 출석 버튼 숨김 처리")
                    self.loginRewardClaimed = true
                    // 사용자 정보 새로고침하여 포인트 업데이트
                    self.loadUser()
                }
            )
            .store(in: &cancellables)
    }
    
    func claimLoginReward() {
        claimDailyLoginReward()
    }
    
    func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

