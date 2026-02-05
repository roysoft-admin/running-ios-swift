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
                        print("[HomeViewModel] ❌ 오늘 통계 로드 실패: \(error)")
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
        var endOfDayComponents = calendar.dateComponents([.year, .month, .day], from: startOfDay)
        endOfDayComponents.hour = 23
        endOfDayComponents.minute = 59
        endOfDayComponents.second = 59
        let endOfDay = calendar.date(from: endOfDayComponents)!
        
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else { return }
        
        print("[HomeViewModel] 📅 오늘 통계 조회: startedAt=\(startOfDay), endedAt=\(endOfDay)")
        
        // Activities와 UserPoints를 병렬로 로드
        let activitiesPublisher = activityService.getActivities(
            startedAt: startOfDay,
            endedAt: endOfDay,
            userUuid: userUuid
        )
        
        let userPointsPublisher = pointService.getUserPoints(
            startedAt: startOfDay,
            endedAt: endOfDay,
            userUuid: userUuid,
            pointType: .earned
        )
        
        Publishers.Zip(
            activitiesPublisher.catch { error -> AnyPublisher<ActivitiesListResponseDTO, Never> in
                print("[HomeViewModel] ❌ Activities 로드 실패: \(error)")
                let emptyActivities = ActivitiesListResponseDTO(activities: [], totalCount: 0)
                return Just(emptyActivities).eraseToAnyPublisher()
            },
            userPointsPublisher.catch { error -> AnyPublisher<UserPointsListResponseDTO, Never> in
                print("[HomeViewModel] ❌ UserPoints 로드 실패: \(error)")
                let emptyUserPoints = UserPointsListResponseDTO(userPoints: [], totalCount: 0)
                return Just(emptyUserPoints).eraseToAnyPublisher()
            }
        )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    // Never이므로 failure 케이스는 없음
                    print("[HomeViewModel] ✅ 오늘 통계 로드 완료")
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
                    let earnedUserPoints = userPointsResponse.userPoints
                        .filter { userPoint in
                            // point 객체의 type이 earned인 것만, 또는 pointAmount가 양수인 것만
                            (userPoint.point?.type == .earned || userPoint.pointAmount > 0)
                        }
                    
                    let totalPoints = earnedUserPoints.reduce(0) { $0 + $1.pointAmount }
                    
                    // 일일 포인트 획득 정보 계산
                    var attendance = false
                    var challenge50 = false
                    var challengeAd30 = false
                    var extraChallenge50 = false
                    var shareCount = 0
                    
                    for userPoint in earnedUserPoints {
                        guard let point = userPoint.point else { continue }
                        
                        if point.title == "출석 보상" && point.point == 10 {
                            attendance = true
                        } else if point.title == "챌린지 완료" && point.point == 50 {
                            challenge50 = true
                        } else if point.title == "챌린지 완료 후 광고 시청" && point.point == 30 {
                            challengeAd30 = true
                        } else if point.title == "추가 챌린지" && point.point == 50 {
                            extraChallenge50 = true
                        } else if point.title == "러닝 공유" && point.point == 5 {
                            shareCount += 1
                        }
                    }
                    
                    // 공유는 최대 5회
                    shareCount = min(shareCount, 5)
                    
                    let dailyPointEarnings = DailyPointEarnings(
                        attendance: attendance,
                        challenge50: challenge50,
                        challengeAd30: challengeAd30,
                        extraChallenge50: extraChallenge50,
                        shareCount: shareCount
                    )
                    
                    // 오늘 날짜 및 요일 표시
                    let dateLabel = self.formatDateLabel(Date())
                    
                    self.dailyStats = DailyStats(
                        distance: totalDistance,
                        time: totalTime,
                        calories: totalCalories,
                        points: totalPoints,
                        dailyPointEarnings: dailyPointEarnings,
                        dateLabel: dateLabel
                    )
                }
            )
            .store(in: &cancellables)
    }
    
    func loadWeeklyStats() {
        let calendar = Calendar.current
        let today = Date()
        
        // 이번 주 월요일 찾기
        let dayOfWeek = calendar.component(.weekday, from: today)
        let daysFromMonday = dayOfWeek == 1 ? 6 : dayOfWeek - 2 // 일요일이면 6, 아니면 dayOfWeek - 2
        let startOfWeek = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!
        let startOfWeekComponents = calendar.dateComponents([.year, .month, .day], from: startOfWeek)
        let startOfWeekDate = calendar.date(from: DateComponents(year: startOfWeekComponents.year, month: startOfWeekComponents.month, day: startOfWeekComponents.day, hour: 0, minute: 0, second: 0))!
        
        // 일요일 23:59:59
        var endOfWeekComponents = calendar.dateComponents([.year, .month, .day], from: startOfWeekDate)
        endOfWeekComponents.day! += 6
        endOfWeekComponents.hour = 23
        endOfWeekComponents.minute = 59
        endOfWeekComponents.second = 59
        let endOfWeek = calendar.date(from: endOfWeekComponents)!
        
        // 주차 계산
        let weekLabel = formatWeekLabel(startOfWeekDate)
        
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else { return }
        
        print("[HomeViewModel] 📅 주간 통계 조회: startedAt=\(startOfWeekDate), endedAt=\(endOfWeek)")
        
        activityService.getActivities(
            startedAt: startOfWeekDate,
            endedAt: endOfWeek,
            userUuid: userUuid
        )
        .catch { error -> AnyPublisher<ActivitiesListResponseDTO, Never> in
            print("[HomeViewModel] ❌ Activities 로드 실패 (주간): \(error)")
            let emptyActivities = ActivitiesListResponseDTO(activities: [], totalCount: 0)
            return Just(emptyActivities).eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                // Never이므로 failure 케이스는 없음
                print("[HomeViewModel] ✅ 주간 통계 로드 완료")
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
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
                    let date = calendar.date(byAdding: .day, value: i, to: startOfWeekDate)!
                    let dayActivities = completedActivities.filter { activity in
                        calendar.isDate(activity.startTime, inSameDayAs: date)
                    }
                    let dayDistance = dayActivities.reduce(0) { $0 + $1.distance }
                    
                    dailyData.append(DailyData(
                        day: dayNames[calendar.component(.weekday, from: date) - 1],
                        distance: dayDistance
                    ))
                }
                
                self.weeklyStats = WeeklyStats(
                    totalDistance: totalDistance,
                    runningCount: completedActivities.count,
                    dailyData: dailyData,
                    weekLabel: weekLabel
                )
            }
        )
        .store(in: &cancellables)
    }
    
    func loadMonthlyStats() {
        let calendar = Calendar.current
        let today = Date()
        
        // 이번 달 1일 0시
        let startOfMonthComponents = calendar.dateComponents([.year, .month], from: today)
        let startOfMonth = calendar.date(from: DateComponents(year: startOfMonthComponents.year, month: startOfMonthComponents.month, day: 1, hour: 0, minute: 0, second: 0))!
        
        // 다음달 1일 0시
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1), to: startOfMonth)!
        
        // 월 표시
        let monthLabel = formatMonthLabel(startOfMonth)
        
        guard let userUuid = currentUserUuid ?? currentUser?.uuid else { return }
        
        print("[HomeViewModel] 📅 월간 통계 조회: startedAt=\(startOfMonth), endedAt=\(endOfMonth)")
        
        // Activities와 UserPoints를 병렬로 로드
        let activitiesPublisher = activityService.getActivities(
            startedAt: startOfMonth,
            endedAt: endOfMonth,
            userUuid: userUuid
        )
        
        // 마지막 날 23:59:59
        var lastDayComponents = calendar.dateComponents([.year, .month, .day], from: endOfMonth)
        lastDayComponents.day! -= 1
        lastDayComponents.hour = 23
        lastDayComponents.minute = 59
        lastDayComponents.second = 59
        let lastDayOfMonth = calendar.date(from: lastDayComponents)!
        
        let userPointsPublisher = pointService.getUserPoints(
            startedAt: startOfMonth,
            endedAt: lastDayOfMonth,
            userUuid: userUuid,
            pointType: .earned
        )
        
        Publishers.Zip(
            activitiesPublisher.catch { error -> AnyPublisher<ActivitiesListResponseDTO, Never> in
                print("[HomeViewModel] ❌ Activities 로드 실패 (월간): \(error)")
                let emptyActivities = ActivitiesListResponseDTO(activities: [], totalCount: 0)
                return Just(emptyActivities).eraseToAnyPublisher()
            },
            userPointsPublisher.catch { error -> AnyPublisher<UserPointsListResponseDTO, Never> in
                print("[HomeViewModel] ❌ UserPoints 로드 실패 (월간): \(error)")
                let emptyUserPoints = UserPointsListResponseDTO(userPoints: [], totalCount: 0)
                return Just(emptyUserPoints).eraseToAnyPublisher()
            }
        )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    // Never이므로 failure 케이스는 없음
                    print("[HomeViewModel] ✅ 월간 통계 로드 완료")
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
                    // endOfMonth는 다음달 1일 0시이므로, 이번 달 마지막 날 23:59:59로 계산
                    let lastDayOfMonth = calendar.date(byAdding: DateComponents(day: -1), to: endOfMonth)!
                    
                    var weeklyData: [WeeklyData] = []
                    var currentWeekStart = startOfMonth
                    var weekNumber = 1
                    
                    while currentWeekStart <= lastDayOfMonth {
                        let weekEnd = min(calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!, lastDayOfMonth)
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
                        weeklyData: weeklyData,
                        monthLabel: monthLabel
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
                    // 오늘의 활동 포인트 및 일일 포인트 획득 새로고침
                    self.loadDailyStats()
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
    
    func formatDateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        let dayNames = ["일", "월", "화", "수", "목", "금", "토"]
        let dayName = dayNames[(components.weekday ?? 1) - 1]
        return String(format: "%d년 %d월 %d일 %@요일", components.year ?? 2026, components.month ?? 1, components.day ?? 1, dayName)
    }
    
    func formatWeekLabel(_ startOfWeek: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: startOfWeek)
        let month = components.month ?? 1
        
        // 해당 주가 속한 월의 몇 번째 주인지 계산
        var firstDayComponents = DateComponents(year: components.year, month: components.month, day: 1)
        let firstDayOfMonth = calendar.date(from: firstDayComponents)!
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysFromFirstMonday = firstDayWeekday == 1 ? 6 : firstDayWeekday - 2
        let firstMondayOfMonth = calendar.date(byAdding: .day, value: -daysFromFirstMonday, to: firstDayOfMonth)!
        
        let daysDiff = calendar.dateComponents([.day], from: firstMondayOfMonth, to: startOfWeek).day ?? 0
        let weekNumber = (daysDiff / 7) + 1
        
        return String(format: "%d월 %d주차", month, weekNumber)
    }
    
    func formatMonthLabel(_ startOfMonth: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: startOfMonth)
        let month = components.month ?? 1
        return String(format: "%d월", month)
    }
}

