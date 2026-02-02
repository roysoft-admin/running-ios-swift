//
//  PointViewModel.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class PointViewModel: ObservableObject {
    @Published var userPoints: [UserPoint] = []
    @Published var points: [Point] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let pointService = PointService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // TODO: Get current user UUID from app state
    var currentUserUuid: String?
    
    // MARK: - Load Points (Static Data)
    
    func loadPoints() {
        isLoading = true
        
        pointService.getPoints()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.points = response.points
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load User Points (History)
    
    func loadUserPoints(
        startDate: Date? = nil,
        endDate: Date? = nil,
        pointUuid: String? = nil,
        pointType: PointType? = nil
    ) {
        isLoading = true
        
        pointService.getUserPoints(
            startDate: startDate,
            endDate: endDate,
            pointUuid: pointUuid,
            pointType: pointType
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
                self?.userPoints = response.userPoints
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Earn Points
    
    func earnPoints(pointUuid: String, referenceUuid: String? = nil) {
        guard let userUuid = currentUserUuid else {
            errorMessage = "사용자 정보를 찾을 수 없습니다"
            return
        }
        
        // Point 엔티티에서 point 값 찾기
        guard let point = points.first(where: { $0.uuid == pointUuid }) else {
            errorMessage = "Point not found"
            return
        }
        
        pointService.createUserPoint(
            userUuid: userUuid,
            pointUuid: pointUuid,
            point: point.point,  // Point 엔티티의 point 값 사용
            referenceUuid: referenceUuid
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                }
            },
            receiveValue: { [weak self] _ in
                // Points earned successfully
                // TODO: Refresh user data to update point balance
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - Daily Login Reward
    
    func claimDailyLoginReward(pointUuid: String) {
        earnPoints(pointUuid: pointUuid)
    }
    
    // MARK: - Running Share
    
    func shareRunning(activityUuid: String, pointUuid: String) {
        // TODO: Implement sharing logic
        // For now, just earn points
        earnPoints(pointUuid: pointUuid, referenceUuid: activityUuid)
    }
    
    // MARK: - Calculate Monthly Stats
    
    func getMonthlyEarned() -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        // 이번 달 1일 00:00:00
        var startOfMonthComponents = calendar.dateComponents([.year, .month], from: now)
        startOfMonthComponents.day = 1
        startOfMonthComponents.hour = 0
        startOfMonthComponents.minute = 0
        startOfMonthComponents.second = 0
        guard let startOfMonth = calendar.date(from: startOfMonthComponents) else { return 0 }
        
        // 다음 달 1일을 구한 후 하루를 빼서 이번 달 마지막 날 구하기
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth),
              let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else { return 0 }
        
        // 이번 달 마지막 날 23:59:59로 설정
        var endOfMonthComponents = calendar.dateComponents([.year, .month, .day], from: endOfMonth)
        endOfMonthComponents.hour = 23
        endOfMonthComponents.minute = 59
        endOfMonthComponents.second = 59
        guard let endOfMonthWithTime = calendar.date(from: endOfMonthComponents) else { return 0 }
        
        return userPoints
            .filter { point in
                guard let createdAt = point.createdAt as Date? else { return false }
                // AOS와 동일하게 pointAmount가 양수이거나 point.type이 earned인 경우만
                return createdAt >= startOfMonth && createdAt <= endOfMonthWithTime &&
                       (point.point?.type == .earned || point.pointAmount > 0)
            }
            .reduce(0) { $0 + $1.pointAmount }
    }
    
    func getMonthlyUsed() -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        // 이번 달 1일 00:00:00
        var startOfMonthComponents = calendar.dateComponents([.year, .month], from: now)
        startOfMonthComponents.day = 1
        startOfMonthComponents.hour = 0
        startOfMonthComponents.minute = 0
        startOfMonthComponents.second = 0
        guard let startOfMonth = calendar.date(from: startOfMonthComponents) else { return 0 }
        
        // 다음 달 1일을 구한 후 하루를 빼서 이번 달 마지막 날 구하기
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth),
              let endOfMonth = calendar.date(byAdding: .day, value: -1, to: nextMonth) else { return 0 }
        
        // 이번 달 마지막 날 23:59:59로 설정
        var endOfMonthComponents = calendar.dateComponents([.year, .month, .day], from: endOfMonth)
        endOfMonthComponents.hour = 23
        endOfMonthComponents.minute = 59
        endOfMonthComponents.second = 59
        guard let endOfMonthWithTime = calendar.date(from: endOfMonthComponents) else { return 0 }
        
        return userPoints
            .filter { point in
                guard let createdAt = point.createdAt as Date? else { return false }
                return createdAt >= startOfMonth && createdAt <= endOfMonthWithTime &&
                       point.point?.type == .used
            }
            .reduce(0) { $0 + $1.pointAmount }
    }
}

