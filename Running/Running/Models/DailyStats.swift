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
}


