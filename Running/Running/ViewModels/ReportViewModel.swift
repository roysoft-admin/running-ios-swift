//
//  ReportViewModel.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class ReportViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var reports: [Activity] = []
    @Published var monthlyStats: MonthlyReportStats = MonthlyReportStats()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    struct MonthlyReportStats {
        var totalRuns: Int = 0
        var totalDistance: Double = 0.0
        var totalPoints: Int = 0
    }
    
    private let activityService = ActivityService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // TODO: Get current user UUID from app state
    var currentUserUuid: String?
    
    init() {
        loadReports()
    }
    
    func loadReports() {
        isLoading = true
        errorMessage = nil
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        guard let userUuid = currentUserUuid else {
            errorMessage = "사용자 정보를 찾을 수 없습니다"
            isLoading = false
            return
        }
        
        activityService.getActivities(
            startDate: startOfMonth,
            endDate: endOfMonth,
            userUuid: userUuid
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                    print("Failed to load reports: \(error)")
                }
            },
            receiveValue: { [weak self] response in
                self?.isLoading = false
                self?.reports = response.activities.sorted { $0.startTime > $1.startTime }
                self?.updateMonthlyStats()
            }
        )
        .store(in: &cancellables)
    }
    
    func updateMonthlyStats() {
        monthlyStats.totalRuns = reports.count
        monthlyStats.totalDistance = reports.reduce(0) { $0 + $1.distance }
        monthlyStats.totalPoints = reports.reduce(0) { $0 + $1.points }
    }
    
    func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
            loadReports()
        }
    }
    
    func nextMonth() {
        // Don't allow going to future months
        let now = Date()
        if Calendar.current.compare(currentMonth, to: now, toGranularity: .month) == .orderedAscending {
            if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
                currentMonth = newDate
                loadReports()
            }
        }
    }
    
    func loadActivityDetail(activityUuid: String, completion: @escaping (Activity?) -> Void) {
        activityService.getActivity(activityUuid: activityUuid)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    if case .failure = result {
                        completion(nil)
                    }
                },
                receiveValue: { response in
                    completion(response.activity)
                }
            )
            .store(in: &cancellables)
    }
    
    func shareActivity(activityUuid: String, pointUuid: String) {
        // TODO: Implement sharing logic
        // - Create share URL
        // - Call POST /user-points with runningShare pointUuid
        // - Check daily limit (max 5 shares per day)
        let pointViewModel = PointViewModel()
        pointViewModel.shareRunning(activityUuid: activityUuid, pointUuid: pointUuid)
    }
    
    func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func getActivityDate(_ activity: Activity) -> Date {
        return activity.startTime
    }
    
    func formatTime(_ seconds: TimeInterval) -> String {
        let safe = max(0, Int(seconds))
        let hours = safe / 3600
        let minutes = (safe / 60) % 60
        let secs = safe % 60
        // 요구사항: 초 단위까지 노출 + 항상 HH:MM:SS 포맷
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
    
    func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d'%02d\"/km", minutes, seconds)
    }
}

