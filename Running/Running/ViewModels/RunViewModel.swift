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
    @Published var showStartModal: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // Activity tracking
    @Published var currentActivityUuid: String?
    @Published var currentChallengeUuid: String?
    @Published var routes: [ActivityRoute] = []
    
    private var timer: Timer?
    private var routeTimer: Timer?
    private var startTime: Date?
    private var activityStartTime: Date?
    private var locationManager: CLLocationManager?
    private var lastLocation: CLLocation?
    private var routeSeq: Int = 0
    
    private let activityService = ActivityService.shared
    private let challengeService = ChallengeService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // TODO: Get current user UUID from app state
    var currentUserUuid: String?
    
    func startRunning(type: RunningType) {
        isLoading = true
        errorMessage = nil
        
        let startTime = Date()
        self.startTime = startTime
        self.activityStartTime = startTime
        
        guard let userUuid = currentUserUuid else {
            errorMessage = "사용자 정보를 찾을 수 없습니다"
            isLoading = false
            return
        }
        
        if type == .aiChallenge {
            // Create challenge first
            challengeService.createChallenge(userUuid: userUuid)
                .flatMap { [weak self] response -> AnyPublisher<ActivityResponseDTO, NetworkError> in
                    guard let self = self else {
                        return Fail(error: NetworkError.unknown).eraseToAnyPublisher()
                    }
                    self.currentChallengeUuid = response.challenge.uuid
                    return self.activityService.createActivity(
                        userUuid: userUuid,
                        challengeUuid: response.challenge.uuid,
                        startTime: startTime
                    )
                }
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.errorDescription
                        }
                    },
                    receiveValue: { [weak self] response in
                        self?.currentActivityUuid = response.activity.uuid
                        self?.isRunning = true
                        self?.isPaused = false
                        self?.startTimer()
                        self?.startLocationTracking()
                        self?.startRouteTracking()
                    }
                )
                .store(in: &cancellables)
        } else {
            // Normal run
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
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.currentActivityUuid = response.activity.uuid
                    self?.isRunning = true
                    self?.isPaused = false
                    self?.startTimer()
                    self?.startLocationTracking()
                    self?.startRouteTracking()
                }
            )
            .store(in: &cancellables)
        }
    }
    
    func pauseRunning() {
        isPaused = true
        timer?.invalidate()
        routeTimer?.invalidate()
    }
    
    func resumeRunning() {
        isPaused = false
        startTimer()
        startRouteTracking()
    }
    
    func stopRunning() {
        guard let activityUuid = currentActivityUuid else { return }
        
        isLoading = true
        let endTime = Date()
        
        // Stop timers
        timer?.invalidate()
        routeTimer?.invalidate()
        timer = nil
        routeTimer = nil
        
        // Calculate average speed
        let averageSpeed = distance > 0 && time > 0 ? (distance / (time / 3600)) : nil
        
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
                    self?.errorMessage = error.errorDescription
                } else {
                    self?.reset()
                }
            },
            receiveValue: { [weak self] _ in
                self?.reset()
            }
        )
        .store(in: &cancellables)
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
        routes = []
        routeSeq = 0
        lastLocation = nil
        startTime = nil
        activityStartTime = nil
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            self.time = elapsed
            
            // Calculate calories (approximate: 65 kcal per km)
            self.calories = Int(self.distance * 65)
            
            // Calculate pace
            if self.distance > 0 {
                self.pace = (elapsed / 60) / self.distance
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
        // Send route data every 2 seconds
        routeTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let activityUuid = self.currentActivityUuid,
                  !self.isPaused else { return }
            
            // TODO: Get actual location from CLLocationManager
            // For now, simulate with last known location or default
            let lat = self.lastLocation?.coordinate.latitude ?? 37.5665
            let long = self.lastLocation?.coordinate.longitude ?? 126.9780
            let speed = self.lastLocation?.speed ?? nil
            let altitude = self.lastLocation?.altitude ?? nil
            
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
    }
    
    private func calculateDistance(lat1: Double, long1: Double, lat2: Double, long2: Double) -> Double {
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
    
    enum RunningType {
        case normal
        case aiChallenge
    }
}

