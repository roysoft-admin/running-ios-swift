//
//  PointPolicy.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

struct PointPolicy {
    // Point IDs (should match backend Points table)
    // 주/월 관련 항목은 미션으로 이동됨
    static let firstSignUp = 1 // 첫 가입 100
    static let dailyLogin = 2 // 출석 10 (하루 1번)
    static let challengeComplete = 3 // 챌린지 완료 30 (하루 2번)
    static let runningShare = 4 // 러닝 공유 5 (하루 5번)
    
    // Daily maximum point limit
    static let dailyMaxPoints = 100
    
    // Point amounts (should match backend Points table)
    static let pointAmounts: [Int: Int] = [
        firstSignUp: 100,
        dailyLogin: 10,
        challengeComplete: 30,
        runningShare: 5
    ]
    
    static func getPointAmount(for pointId: Int) -> Int {
        return pointAmounts[pointId] ?? 0
    }
}


