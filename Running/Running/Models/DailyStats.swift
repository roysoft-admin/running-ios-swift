//
//  DailyStats.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

struct DailyStats {
    let distance: Double // km
    let time: TimeInterval // seconds
    let calories: Int
    let points: Int
    let dailyPointEarnings: DailyPointEarnings
}

struct DailyPointEarnings {
    let attendance: Bool // 출석 10
    let challenge50: Bool // 챌린지 50
    let challengeAd30: Bool // 챌린지 완료 후 광고 시청 30
    let extraChallenge50: Bool // 추가 챌린지 50
    let shareCount: Int // 공유 5 (1/5)
}

struct WeeklyStats {
    let totalDistance: Double
    let runningCount: Int
    let dailyData: [DailyData]
}

struct DailyData {
    let day: String
    let distance: Double
}

struct MonthlyStats {
    let totalDistance: Double
    let runningCount: Int
    let earnedPoints: Int
    let weeklyData: [WeeklyData]
}

struct WeeklyData {
    let week: String
    let distance: Double
}

struct Achievement {
    let id: String
    let title: String
    let description: String
    let progress: Double
    let target: Double
    let isCompleted: Bool
    let rewardPoints: Int
    let status: UserMissionStatus  // 서버 상태 추가
    let term: MissionTerm  // 미션 기간 추가
    let createdAt: Date  // 미션 시작일 추가
}


