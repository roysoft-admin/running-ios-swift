//
//  RunViewModel.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine
import CoreLocation

class RunViewModel: ObservableObject {
    @Published var distance: Double = 0.00
    @Published var time: TimeInterval = 0
    @Published var pace: Double = 0
    @Published var calories: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var pausedTime: TimeInterval = 0 // 일시정지 시간 (0초부터 카운트)
    @Published var showStartModal: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var startSuccess: Bool? = nil // 러닝 시작 성공 여부 (nil: 초기값, true: 성공, false: 실패)
    @Published var countdown: Int? = nil // 카운트다운 (3, 2, 1, nil = Go 표시)
    
    // Challenge info display
    @Published var showChallengeInfo: Bool = false // 챌린지 정보 표시 화면
    @Published var pendingChallenge: Challenge? // 대기 중인 챌린지 정보
    
    // Activity tracking
    @Published var currentActivityUuid: String?
    @Published var currentChallengeUuid: String?
    @Published var currentChallenge: Challenge? // 현재 진행 중인 챌린지 정보
    @Published var completedActivityUuid: String? // 종료된 활동 UUID (리포트 상세 화면으로 이동용)
    @Published var routes: [ActivityRoute] = []
    
    private var timer: Timer?
    private var routeTimer: Timer?
    private var countdownTimer: Timer?
    private var pauseTimer: Timer? // 일시정지 시간 카운트용 타이머
    private var startTime: Date?
    private var activityStartTime: Date?
    private var pauseStartTime: Date? // 일시정지 시작 시간
    private var totalPausedTime: TimeInterval = 0 // 누적된 일시정지 시간
    private var currentPauseUuid: String? // 현재 일시정지 중인 pause의 UUID
    private var locationManager: CLLocationManager?
    private var lastLocation: CLLocation?
    private var routeSeq: Int = 0
    
    // 최근 30초간의 위치 데이터 (시속 계산용)
    private struct LocationWithTime {
        let timestamp: Date
        let lat: Double
        let long: Double
    }
    private var recentLocations: [LocationWithTime] = []
    
    private let activityService = ActivityService.shared
    private let challengeService = ChallengeService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // TODO: Get current user UUID from app state
    var currentUserUuid: String?
    
    /// 챌린지 선택 시 호출: pending 챌린지 조회 또는 생성
    func selectChallenge() {
        print("[RunViewModel] 🔵 챌린지 선택 요청")
        isLoading = true
        errorMessage = nil
        pendingChallenge = nil
        
        guard let userUuid = currentUserUuid else {
            print("[RunViewModel] ❌ 사용자 UUID가 없습니다")
            errorMessage = "사용자 정보를 찾을 수 없습니다"
            isLoading = false
            return
        }
        
        print("[RunViewModel] ✅ 사용자 UUID: \(userUuid)")
        print("[RunViewModel] 📤 대기 중인 챌린지 조회 시작")
        
        // 먼저 pending 챌린지 조회
        challengeService.getPendingChallenge(userUuid: userUuid)
            .map { (response: ChallengeResponseDTO) -> Challenge in
                return response.challenge
            }
            .catch { [weak self] error -> AnyPublisher<Challenge, NetworkError> in
                guard let self = self else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                
                // 404 에러면 챌린지가 없는 것이므로 새로 생성
                if case .serverError(let code, _) = error, code == 404 {
                    print("[RunViewModel] 📤 대기 중인 챌린지 없음, 새로 생성")
                    return self.challengeService.createChallenge(userUuid: userUuid)
                        .tryMap { (response: ChallengesResponseDTO) -> Challenge in
                            guard let challenge = response.challenges.first else {
                                let error = NSError(domain: "RunViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "챌린지 응답에 데이터가 없습니다"])
                                throw NetworkError.decodingError(error)
                            }
                            return challenge
                        }
                        .mapError { error -> NetworkError in
                            if let networkError = error as? NetworkError {
                                return networkError
                            }
                            return NetworkError.unknown
                        }
                        .eraseToAnyPublisher()
                }
                
                // 다른 에러면 그대로 전달
                return Fail(error: error).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("[RunViewModel] ❌ 챌린지 조회/생성 실패: \(error)")
                        self?.errorMessage = error.errorDescription
                    } else {
                        print("[RunViewModel] ✅ 챌린지 조회/생성 성공")
                    }
                },
                receiveValue: { [weak self] challenge in
                    guard let self = self else { return }
                    print("[RunViewModel] ✅ 챌린지 준비 완료: UUID=\(challenge.uuid)")
                    self.pendingChallenge = challenge
                    self.currentChallengeUuid = challenge.uuid
                    self.currentChallenge = challenge // 현재 챌린지 정보 저장
                    self.showChallengeInfo = true
                }
            )
            .store(in: &cancellables)
    }
    
    /// 챌린지 정보 화면에서 시작 버튼 클릭 시 호출
    func startChallengeRunning() {
        guard let challengeUuid = currentChallengeUuid else {
            errorMessage = "챌린지 정보가 없습니다"
            return
        }
        
        print("[RunViewModel] 🔵 챌린지 러닝 시작 요청")
        isLoading = true
        errorMessage = nil
        startSuccess = nil
        
        let startTime = Date()
        self.startTime = startTime
        self.activityStartTime = startTime
        self.pauseStartTime = nil
        self.totalPausedTime = 0
        self.time = 0
        
        guard let userUuid = currentUserUuid else {
            print("[RunViewModel] ❌ 사용자 UUID가 없습니다")
            errorMessage = "사용자 정보를 찾을 수 없습니다"
            isLoading = false
            startSuccess = false
            return
        }
        
        print("[RunViewModel] ✅ 사용자 UUID: \(userUuid)")
        print("[RunViewModel] 📤 활동 생성 API 호출: challengeUuid=\(challengeUuid), startTime=\(startTime)")
        
        // Activity 생성 (챌린지 연결)
        activityService.createActivity(
            userUuid: userUuid,
            challengeUuid: challengeUuid,
            startTime: startTime
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("[RunViewModel] ❌ 활동 시작 실패: \(error)")
                    self?.errorMessage = error.errorDescription
                    self?.startSuccess = false
                    // 실패 시 타이머 중지 및 상태 리셋
                    self?.timer?.invalidate()
                    self?.routeTimer?.invalidate()
                    self?.isRunning = false
                    self?.resetRunningState()
                } else {
                    print("[RunViewModel] ✅ 활동 시작 성공")
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                print("[RunViewModel] ✅ 활동 생성 성공: UUID=\(response.activity.uuid)")
                self.currentActivityUuid = response.activity.uuid
                self.startSuccess = true
                self.showChallengeInfo = false // 챌린지 정보 화면 닫기
                // 성공 시 카운트다운 시작
                self.startCountdown()
            }
        )
        .store(in: &cancellables)
    }
    
    func startRunning(type: RunningType) {
        print("[RunViewModel] 🔵 러닝 시작 요청: type=\(type == .normal ? "일반" : "AI 챌린지")")
        
        if type == .aiChallenge {
            // 챌린지 선택 로직으로 변경
            selectChallenge()
            return
        }
        
        // 일반 러닝은 기존 로직 유지
        isLoading = true
        errorMessage = nil
        startSuccess = nil
        
        let startTime = Date()
        self.startTime = startTime
        self.activityStartTime = startTime
        self.pauseStartTime = nil
        self.totalPausedTime = 0
        self.time = 0
        
        guard let userUuid = currentUserUuid else {
            print("[RunViewModel] ❌ 사용자 UUID가 없습니다")
            errorMessage = "사용자 정보를 찾을 수 없습니다"
            isLoading = false
            startSuccess = false
            return
        }
        
        print("[RunViewModel] ✅ 사용자 UUID: \(userUuid)")
        print("[RunViewModel] 📤 일반 러닝 활동 생성 API 호출")
            activityService.createActivity(
                userUuid: userUuid,
                challengeUuid: nil,
                startTime: startTime
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("[RunViewModel] ❌ 활동 시작 실패: \(error)")
                        self?.errorMessage = error.errorDescription
                        self?.startSuccess = false
                        // 실패 시 타이머 중지 및 상태 리셋
                        self?.timer?.invalidate()
                        self?.routeTimer?.invalidate()
                        self?.isRunning = false
                        self?.resetRunningState()
                    } else {
                        print("[RunViewModel] ✅ 활동 시작 성공")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    print("[RunViewModel] ✅ 활동 생성 성공: UUID=\(response.activity.uuid)")
                    self.currentActivityUuid = response.activity.uuid
                    self.startSuccess = true
                    // 성공 시 카운트다운 시작
                    self.startCountdown()
                }
            )
            .store(in: &cancellables)
    }
    
    func pauseRunning() {
        guard !isPaused else { return }
        guard let activityUuid = currentActivityUuid else {
            print("[RunViewModel] ⚠️ Activity UUID가 없어 일시정지 API를 호출할 수 없습니다")
            return
        }
        
        isPaused = true
        let pauseStart = Date()
        pauseStartTime = pauseStart
        pausedTime = 0 // 일시정지 시간 0초부터 시작
        timer?.invalidate()
        routeTimer?.invalidate()
        
        // 일시정지 시간 카운트 타이머 시작
        startPauseTimer()
        
        // 일시정지 생성 API 호출
        activityService.createActivityPause(
            activityUuid: activityUuid,
            pauseStartedAt: pauseStart
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("[RunViewModel] ❌ 일시정지 생성 실패: \(error)")
                    // 에러가 발생해도 일시정지 상태는 유지
                }
            },
            receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.currentPauseUuid = response.activityPause.uuid
                print("[RunViewModel] ✅ 일시정지 생성 성공: UUID=\(response.activityPause.uuid)")
            }
        )
        .store(in: &cancellables)
    }
    
    func resumeRunning() {
        guard isPaused, let pauseStart = pauseStartTime else { return }
        guard let pauseUuid = currentPauseUuid else {
            print("[RunViewModel] ⚠️ Pause UUID가 없어 일시정지 종료 API를 호출할 수 없습니다")
            // API 호출 없이 로컬에서만 처리
            let pausedDuration = Date().timeIntervalSince(pauseStart)
            totalPausedTime += pausedDuration
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isPaused = false
                self.pauseStartTime = nil
                self.startTimer()
                self.startRouteTracking()
            }
            return
        }
        
        // 일시정지한 시간을 누적
        let pausedDuration = Date().timeIntervalSince(pauseStart)
        totalPausedTime += pausedDuration
        
        let pauseEnd = Date()
        
        // 일시정지 종료 API 호출
        activityService.updateActivityPause(
            pauseUuid: pauseUuid,
            pauseEndedAt: pauseEnd
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    print("[RunViewModel] ❌ 일시정지 종료 실패: \(error)")
                    // 에러가 발생해도 재개는 진행
                }
            },
            receiveValue: { [weak self] _ in
                guard let self = self else { return }
                print("[RunViewModel] ✅ 일시정지 종료 성공")
            }
        )
        .store(in: &cancellables)
        
        // 메인 스레드에서 상태 변경 및 타이머 재시작
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isPaused = false
            self.pauseStartTime = nil
            self.currentPauseUuid = nil
            self.pausedTime = 0 // 일시정지 시간 리셋
            self.pauseTimer?.invalidate() // 일시정지 타이머 정지
            self.pauseTimer = nil
            self.startTimer()
            self.startRouteTracking()
        }
    }
    
    func stopRunning() {
        // 이미 종료되었거나 실행 중이 아니면 무시
        guard isRunning else { 
            print("[RunViewModel] ⚠️ 이미 종료되었거나 실행 중이 아닙니다")
            return 
        }
        
        print("[RunViewModel] 🔴 러닝 종료 요청 (isLoading: \(isLoading))")
        
        // 진행 중인 API 호출 취소 (필요한 경우)
        cancellables.removeAll()
        
        // 일시정지 중이면 일시정지 종료 API 호출
        if isPaused {
            let pausedDuration = Date().timeIntervalSince(pauseStartTime ?? Date())
            totalPausedTime += pausedDuration
            
            if let pauseUuid = currentPauseUuid {
                let pauseEnd = Date()
                activityService.updateActivityPause(
                    pauseUuid: pauseUuid,
                    pauseEndedAt: pauseEnd
                )
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            print("[RunViewModel] ❌ 일시정지 종료 실패 (stopRunning): \(error)")
                            // 에러가 발생해도 종료는 진행
                        } else {
                            print("[RunViewModel] ✅ 일시정지 종료 성공 (stopRunning)")
                        }
                    },
                    receiveValue: { [weak self] _ in
                        print("[RunViewModel] ✅ 일시정지 종료 성공 (stopRunning)")
                    }
                )
                .store(in: &cancellables)
            }
            
            isPaused = false
            pauseStartTime = nil
            pausedTime = 0
            pauseTimer?.invalidate()
            pauseTimer = nil
            currentPauseUuid = nil
        }
        
        // Stop timers immediately
        timer?.invalidate()
        routeTimer?.invalidate()
        pauseTimer?.invalidate()
        timer = nil
        routeTimer = nil
        pauseTimer = nil
        
        // 최종 시간 계산
        if let startTime = startTime {
            let currentElapsed = Date().timeIntervalSince(startTime)
            time = max(0, currentElapsed - totalPausedTime)
        }
        
        // UI 상태를 즉시 변경 (사용자에게 즉시 피드백)
        isRunning = false
        
        // Activity UUID가 없으면 로컬에서만 종료 처리
        guard let activityUuid = currentActivityUuid else {
            print("[RunViewModel] ⚠️ Activity UUID가 없어 로컬에서만 종료 처리")
            completedActivityUuid = nil
            reset()
            return
        }
        
        // 서버 업데이트는 백그라운드에서 처리
        isLoading = true
        let endTime = Date()
        
        // Calculate average speed
        let averageSpeed = distance > 0 && time > 0 ? (distance / (time / 3600)) : nil
        
        print("[RunViewModel] 🔴 서버에 활동 종료 전송: distance=\(distance), time=\(time), calories=\(calories)")
        
        // Update activity on server
        // Note: distance and end_time are calculated on backend, but we send current values
        activityService.updateActivity(
            activityUuid: activityUuid,
            distance: distance,
            endTime: endTime,
            averageSpeed: averageSpeed,
            calories: calories
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("[RunViewModel] ❌ 활동 종료 실패: \(error)")
                    self?.errorMessage = error.errorDescription
                    // 실패해도 로컬 상태는 이미 리셋됨
                } else {
                    print("[RunViewModel] ✅ 활동 종료 성공")
                    // 리포트 상세 화면으로 이동하기 위해 UUID 저장
                    self?.completedActivityUuid = activityUuid
                    self?.reset()
                }
            },
            receiveValue: { [weak self] _ in
                print("[RunViewModel] ✅ 활동 종료 성공")
                // 리포트 상세 화면으로 이동하기 위해 UUID 저장
                self?.completedActivityUuid = activityUuid
                self?.reset()
            }
        )
        .store(in: &cancellables)
    }
    
    private func resetRunningState() {
        // 러닝 시작 실패 시 상태만 리셋 (completedActivityUuid는 유지)
        isRunning = false
        isPaused = false
        distance = 0.00
        time = 0
        pace = 0
        calories = 0
        currentActivityUuid = nil
        currentChallengeUuid = nil
        routes = []
        routeSeq = 0
        lastLocation = nil
        startTime = nil
        activityStartTime = nil
        pauseStartTime = nil
        totalPausedTime = 0
        currentPauseUuid = nil
        pausedTime = 0
        pauseTimer?.invalidate()
        pauseTimer = nil
    }
    
    private func reset() {
        isRunning = false
        isPaused = false
        distance = 0.00
        time = 0
        pace = 0
        calories = 0
        currentActivityUuid = nil
        currentChallengeUuid = nil
        // completedActivityUuid는 리포트 상세 화면으로 이동 후에 nil로 설정됨
        routes = []
        routeSeq = 0
        lastLocation = nil
        startTime = nil
        activityStartTime = nil
        pauseStartTime = nil
        totalPausedTime = 0
        currentPauseUuid = nil
    }
    
    private func startTimer() {
        // 기존 타이머가 있으면 먼저 정리
        timer?.invalidate()
        
        // 메인 스레드에서 타이머 생성 및 시작
        let timerBlock: () -> Void = { [weak self] in
            guard let self = self, let startTime = self.startTime else { return }
            
            // 일시정지 시간을 제외한 실제 경과 시간 계산
            let currentElapsed = Date().timeIntervalSince(startTime)
            var actualElapsed = currentElapsed - self.totalPausedTime
            
            // 현재 일시정지 중이면 추가로 빼기
            if let pauseStart = self.pauseStartTime {
                let currentPaused = Date().timeIntervalSince(pauseStart)
                actualElapsed -= currentPaused
            }
            
            // 시간이 음수가 되지 않도록 보장
            self.time = max(0, actualElapsed)
            
            // Calculate calories (approximate: 65 kcal per km)
            self.calories = Int(self.distance * 65)
            
            // Calculate pace
            if self.distance > 0 && self.time > 0 {
                self.pace = (self.time / 60) / self.distance
            } else {
                self.pace = 0
            }
        }
        
        if Thread.isMainThread {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                timerBlock()
            }
            // 타이머를 메인 RunLoop에 명시적으로 추가 (다양한 모드에서도 작동하도록)
            if let timer = self.timer {
                RunLoop.main.add(timer, forMode: .common)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    timerBlock()
                }
                // 타이머를 메인 RunLoop에 명시적으로 추가 (다양한 모드에서도 작동하도록)
                if let timer = self.timer {
                    RunLoop.main.add(timer, forMode: .common)
                }
            }
        }
    }
    
    private func startLocationTracking() {
        // TODO: Implement CoreLocation for actual GPS tracking
        // For now, simulate location updates
        locationManager = CLLocationManager()
        // Request location permissions and start tracking
    }
    
    private func startRouteTracking() {
        // 기존 routeTimer가 있으면 먼저 정리
        routeTimer?.invalidate()
        
        // 메인 스레드에서 routeTimer 생성 및 시작
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.routeTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                guard let self = self,
                      let activityUuid = self.currentActivityUuid,
                      !self.isPaused else { return }
            
            // TODO: Get actual location from CLLocationManager
            // For now, simulate with last known location or default
            let lat = self.lastLocation?.coordinate.latitude ?? 37.5665
            let long = self.lastLocation?.coordinate.longitude ?? 126.9780
            let speed = self.lastLocation?.speed ?? nil
            let altitude = self.lastLocation?.altitude ?? nil
            
            // 최근 30초간의 위치 데이터 저장 (시속 계산용)
            let now = Date()
            self.recentLocations.append(LocationWithTime(timestamp: now, lat: lat, long: long))
            // 30초 이전 데이터 제거
            self.recentLocations.removeAll { location in
                now.timeIntervalSince(location.timestamp) > 30.0
            }
            
            self.routeSeq += 1
            
            // Note: ActivityRoute의 activityId는 내부적으로만 사용 (DB 관계용)
            // API 호출 시에는 activityUuid 사용
            let route = ActivityRoute(
                id: 0, // Will be set by server
                uuid: UUID().uuidString,
                createdAt: Date(),
                deletedAt: nil,
                activityId: 0, // Not used in API call
                lat: lat,
                long: long,
                speed: speed != nil ? Double(speed!) : nil,
                altitude: altitude != nil ? Double(altitude!) : nil,
                seq: self.routeSeq
            )
            
            self.routes.append(route)
            
            // Send to server
            self.activityService.createActivityRoute(
                activityUuid: activityUuid,
                lat: lat,
                long: long,
                speed: speed != nil ? Double(speed!) : nil,
                altitude: altitude != nil ? Double(altitude!) : nil,
                seq: self.routeSeq
            )
            .sink(
                receiveCompletion: { completion in
                    // Silently handle errors for route tracking
                    if case .failure(let error) = completion {
                        print("Route tracking error: \(error)")
                    }
                },
                receiveValue: { _ in
                    // Route saved successfully
                }
            )
            .store(in: &self.cancellables)
            
            // Update distance based on route
            if self.routes.count > 1 {
                let previousRoute = self.routes[self.routes.count - 2]
                let distanceDelta = self.calculateDistance(
                    lat1: previousRoute.lat,
                    long1: previousRoute.long,
                    lat2: lat,
                    long2: long
                )
                self.distance += distanceDelta / 1000.0 // Convert to km
            }
            }
            
            // routeTimer를 메인 RunLoop에 명시적으로 추가
            if let routeTimer = self.routeTimer {
                RunLoop.main.add(routeTimer, forMode: .common)
            }
        }
    }
    
    func calculateDistance(lat1: Double, long1: Double, lat2: Double, long2: Double) -> Double {
        let location1 = CLLocation(latitude: lat1, longitude: long1)
        let location2 = CLLocation(latitude: lat2, longitude: long2)
        return location1.distance(from: location2)
    }
    
    func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"/km", minutes, seconds)
    }
    
    // 시속 계산 (km/h) - 최근 30초간의 이동 거리 기준
    var speed: Double {
        guard recentLocations.count >= 2 else { return 0 }
        
        let now = Date()
        // 30초 이전 위치 찾기
        guard let oldestLocation = recentLocations.first(where: { location in
            now.timeIntervalSince(location.timestamp) <= 30.0
        }) else {
            // 30초 이전 데이터가 없으면 가장 오래된 데이터 사용
            guard let oldest = recentLocations.first,
                  let newest = recentLocations.last else { return 0 }
            
            let timeDiff = newest.timestamp.timeIntervalSince(oldest.timestamp)
            guard timeDiff > 0 else { return 0 }
            
            let distance = calculateDistance(
                lat1: oldest.lat,
                long1: oldest.long,
                lat2: newest.lat,
                long2: newest.long
            ) / 1000.0 // km로 변환
            
            return (distance * 3600) / timeDiff
        }
        
        // 가장 최근 위치
        guard let newestLocation = recentLocations.last else { return 0 }
        
        let timeDiff = newestLocation.timestamp.timeIntervalSince(oldestLocation.timestamp)
        guard timeDiff > 0 else { return 0 }
        
        let distance = calculateDistance(
            lat1: oldestLocation.lat,
            long1: oldestLocation.long,
            lat2: newestLocation.lat,
            long2: newestLocation.long
        ) / 1000.0 // km로 변환
        
        return (distance * 3600) / timeDiff
    }
    
    func formatSpeed(_ speed: Double) -> String {
        return String(format: "%.1f km/h", speed)
    }
    
    // 일시정지 시간 카운트 타이머 시작
    private func startPauseTimer() {
        pauseTimer?.invalidate()
        pausedTime = 0
        
        pauseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isPaused else {
                self?.pauseTimer?.invalidate()
                return
            }
            self.pausedTime += 1.0
        }
        
        if let pauseTimer = pauseTimer {
            RunLoop.main.add(pauseTimer, forMode: .common)
        }
    }
    
    // 카운트다운 시작
    private func startCountdown() {
        countdown = 3
        countdownTimer?.invalidate()
        
        var currentCount = 3
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentCount -= 1
            
            if currentCount > 0 {
                self.countdown = currentCount
            } else if currentCount == 0 {
                // Go 표시를 위해 -1로 설정 (nil과 구분)
                self.countdown = -1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Go 표시 후 실제 러닝 시작 - 카운트다운이 끝난 시점을 시작 시간으로 설정
                    let actualStartTime = Date()
                    self.startTime = actualStartTime
                    self.activityStartTime = actualStartTime
                    self.time = 0
                    self.totalPausedTime = 0
                    
                    // 백엔드의 start_time을 카운트다운 종료 시점으로 업데이트
                    if let activityUuid = self.currentActivityUuid {
                        self.activityService.updateActivity(
                            activityUuid: activityUuid,
                            distance: nil,
                            endTime: nil,
                            averageSpeed: nil,
                            calories: nil,
                            startTime: actualStartTime
                        )
                        .receive(on: DispatchQueue.main)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    print("[RunViewModel] ⚠️ start_time 업데이트 실패: \(error)")
                                } else {
                                    print("[RunViewModel] ✅ start_time 업데이트 성공")
                                }
                            },
                            receiveValue: { _ in }
                        )
                        .store(in: &self.cancellables)
                    }
                    
                    self.countdown = nil
                    self.isRunning = true
                    self.isPaused = false
                    self.startTimer()
                    self.startLocationTracking()
                    self.startRouteTracking()
                    timer.invalidate()
                    print("[RunViewModel] ✅ 타이머 및 경로 추적 시작 (실제 시작 시간: \(actualStartTime))")
                }
            }
        }
    }
    
    /// 종료되지 않은 activity의 러닝 상태 복원
    func restoreRunningState(startTime: Date) {
        print("[RunViewModel] 🔵 러닝 상태 복원 시작: startTime=\(startTime)")
        
        self.startTime = startTime
        self.activityStartTime = startTime
        self.pauseStartTime = nil
        self.totalPausedTime = 0
        
        // 경과 시간 계산
        let elapsed = Date().timeIntervalSince(startTime)
        self.time = max(0, elapsed)
        
        // 러닝 상태 설정
        self.isRunning = true
        self.isPaused = false
        
        // 타이머 및 위치 추적 시작
        startTimer()
        startLocationTracking()
        startRouteTracking()
        
        print("[RunViewModel] ✅ 러닝 상태 복원 완료: time=\(self.time)초")
    }
    
    enum RunningType {
        case normal
        case aiChallenge
    }
}

