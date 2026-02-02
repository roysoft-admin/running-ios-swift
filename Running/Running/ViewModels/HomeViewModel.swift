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
    @Published var loginRewardClaimed: Bool = true  // 초기값 true: API 체크 완료 전까지 버튼 숨김
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
                    } else {
                        print("[HomeViewModel] ⚠️ 출석 보상 Point를 찾을 수 없습니다")
                    }
                    
                    // Point UUID 설정 후, 사용자 정보가 이미 로드되어 있으면 출석 보상 체크
                    // 사용자 정보가 아직 로드되지 않았으면 loadUser() 완료 후 자동으로 체크됨
                    if self.currentUser != nil || self.currentUserUuid != nil {
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
                    guard let self = self else { return }
                    self.currentUser = response.user
                    self.currentPoints = response.user.point
                    self.currentUserUuid = response.user.uuid
                    
                    // 사용자 정보 로드 완료 후 출석 보상 체크 (dailyLoginPointUuid가 설정되어 있을 때만)
                    if self.dailyLoginPointUuid != nil {
                        self.checkAndClaimDailyLoginReward()
                    }
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
        
        // Activities와 UserPoints를 병렬로 로드
        let activitiesPublisher = activityService.getActivities(
            startDate: startOfDay,
            endDate: endOfDay,
            userUuid: userUuid
        )
        
        let userPointsPublisher = pointService.getUserPoints(
            startDate: startOfDay,
            endDate: endOfDay,
            userUuid: userUuid,
            pointType: .earned
        )
        
        Publishers.Zip(activitiesPublisher, userPointsPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] (activitiesResponse, userPointsResponse) in
                    guard let self = self else { return }
                    let allActivities = activitiesResponse.activities
                    
                    // 완료된 활동만 필터링 (endTime이 있고 실제로 종료된 활동, 거리는 0이어도 시간이 있으면 포함)
                    let completedActivities = allActivities.filter { activity in
                        activity.endTime != nil && activity.endTime! > activity.startTime
                    }
                    
                    let totalDistance = completedActivities.reduce(0) { $0 + $1.distance }
                    let totalTime = completedActivities.reduce(0) { $0 + $1.actualRunningTime }
                    let totalCalories = completedActivities.reduce(0) { $0 + ($1.calories ?? 0) }
                    
                    print("[HomeViewModel] 📊 오늘 통계: 활동 \(completedActivities.count)개, 거리 \(totalDistance)km, 시간 \(totalTime)초, 칼로리 \(totalCalories)")
                    for activity in completedActivities {
                        let pauseCount = activity.pauses?.count ?? 0
                        let pausedTime = activity.pauses?.reduce(0) { sum, pause in
                            if let pauseEndedAt = pause.pauseEndedAt {
                                return sum + pauseEndedAt.timeIntervalSince(pause.pauseStartedAt)
                            }
                            return sum + Date().timeIntervalSince(pause.pauseStartedAt)
                        } ?? 0
                        print("[HomeViewModel] 📊 Activity \(activity.uuid): actualRunningTime=\(activity.actualRunningTime)초, pauses=\(pauseCount)개, pausedTime=\(pausedTime)초")
                    }
                    
                    // 오늘 획득한 모든 포인트 합산 (UserPoint의 pointAmount 사용)
                    // userUuid로 필터링하여 현재 사용자의 포인트만 계산
                    let totalPoints = userPointsResponse.userPoints
                        .filter { userPoint in
                            // point 객체의 type이 earned인 것만, 또는 pointAmount가 양수인 것만
                            (userPoint.point?.type == .earned || userPoint.pointAmount > 0)
                        }
                        .reduce(0) { $0 + $1.pointAmount }
                    
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
                
                // 완료된 활동만 필터링 (distance > 0이고 endTime이 있는 활동)
                let completedActivities = allActivities.filter { activity in
                    activity.distance > 0 && activity.endTime != nil && activity.endTime! > activity.startTime
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
        
        // Activities와 UserPoints를 병렬로 로드
        let activitiesPublisher = activityService.getActivities(
            startDate: startOfMonth,
            endDate: endOfMonth,
            userUuid: userUuid
        )
        
        let userPointsPublisher = pointService.getUserPoints(
            startDate: startOfMonth,
            endDate: endOfMonth,
            userUuid: userUuid,
            pointType: .earned
        )
        
        Publishers.Zip(activitiesPublisher, userPointsPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] (activitiesResponse, userPointsResponse) in
                    guard let self = self else { return }
                    let allActivities = activitiesResponse.activities
                    
                    // 완료된 활동만 필터링 (endTime이 있고 실제로 종료된 활동, 거리는 0이어도 시간이 있으면 포함)
                    let completedActivities = allActivities.filter { activity in
                        activity.endTime != nil && activity.endTime! > activity.startTime
                    }
                    
                    let totalDistance = completedActivities.reduce(0) { $0 + $1.distance }
                    
                    // 이번달 획득한 모든 포인트 합산 (UserPoint의 pointAmount 사용)
                    let totalPoints = userPointsResponse.userPoints
                        .filter { userPoint in
                            // point 객체의 type이 earned인 것만, 또는 pointAmount가 양수인 것만
                            (userPoint.point?.type == .earned || userPoint.pointAmount > 0)
                        }
                        .reduce(0) { $0 + $1.pointAmount }
                    
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
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else {
            print("[HomeViewModel] ⚠️ 사용자 UUID를 찾을 수 없어 미션을 로드할 수 없습니다")
            return
        }
        
        print("[HomeViewModel] 🔵 미션 로드 시작: userUuid=\(userUuid)")
        
        // 진행중 + 완료된 미션 모두 조회 (status 필터 없음)
        missionService.getUserMissions(
            userUuid: userUuid,
            status: nil,  // 모든 상태 조회
            startDate: nil,
            endDate: nil
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("[HomeViewModel] ❌ 미션 로드 실패: \(error)")
                    self?.errorMessage = error.errorDescription
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                print("[HomeViewModel] 📥 미션 응답 받음: userMissions.count=\(response.userMissions.count)")
                
                var validAchievements: [Achievement] = []
                var skippedCount = 0
                
                // 진행중 또는 완료된 미션만 필터링
                let filteredMissions = response.userMissions.filter { userMission in
                    userMission.status == .inProgress || userMission.status == .completed
                }
                
                // term과 type 조합별로 그룹화 (월간 거리, 월간 챌린지, 주간 거리, 주간 챌린지)
                struct MissionKey: Hashable {
                    let term: MissionTerm
                    let type: MissionType
                }
                
                var missionsByKey: [MissionKey: [UserMission]] = [:]
                for userMission in filteredMissions {
                    guard let mission = userMission.mission else {
                        skippedCount += 1
                        continue
                    }
                    let key = MissionKey(term: mission.term, type: mission.type)
                    if missionsByKey[key] == nil {
                        missionsByKey[key] = []
                    }
                    missionsByKey[key]?.append(userMission)
                }
                
                // 각 조합별로 최근 1개씩 선택 (createdAt 기준 내림차순)
                var achievementsByKey: [MissionKey: Achievement] = [:]
                for (key, userMissions) in missionsByKey {
                    let sortedMissions = userMissions.sorted { $0.createdAt > $1.createdAt }
                    guard let userMission = sortedMissions.first,
                          let mission = userMission.mission else {
                        continue
                    }
                    
                    let progress = Double(userMission.userValue)
                    let target = Double(mission.targetValue)
                    let isCompleted = userMission.status == .completed
                    
                    let achievement = Achievement(
                        id: String(userMission.id),
                        title: mission.title,
                        description: "\(userMission.userValue)/\(mission.targetValue)",
                        progress: progress,
                        target: target,
                        isCompleted: isCompleted,
                        rewardPoints: mission.point,
                        status: userMission.status,
                        term: mission.term,
                        createdAt: userMission.createdAt
                    )
                    
                    achievementsByKey[key] = achievement
                    print("[HomeViewModel] ✅ Achievement 추가: \(mission.title) (term: \(mission.term.rawValue), type: \(mission.type.rawValue), status: \(userMission.status.rawValue))")
                }
                
                // 지정된 순서대로 정렬: 주간 챌린지 > 주간 거리 > 월간 챌린지 > 월간 거리
                let orderedKeys: [MissionKey] = [
                    MissionKey(term: .week, type: .challengeCount),
                    MissionKey(term: .week, type: .totalDistance),
                    MissionKey(term: .month, type: .challengeCount),
                    MissionKey(term: .month, type: .totalDistance)
                ]
                
                for key in orderedKeys {
                    if let achievement = achievementsByKey[key] {
                        validAchievements.append(achievement)
                    }
                }
                
                print("[HomeViewModel] ✅ 총 \(validAchievements.count)개의 미션 표시 (type별 최근 1개씩), \(skippedCount)개 건너뜀")
                self.achievements = validAchievements
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
                    // 에러 시 버튼 표시 (출석 보상을 받지 않았을 가능성이 높음)
                    self?.loginRewardClaimed = false
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
                    // 출석 보상을 받지 않았으면 버튼 표시 (자동 클레임 제거)
                    self.loginRewardClaimed = false
                    print("[HomeViewModel] ✅ 출석 보상 버튼 표시 (사용자가 직접 클릭해야 함)")
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

