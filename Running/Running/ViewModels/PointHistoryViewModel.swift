//
//  PointHistoryViewModel.swift
//  Running
//
//  Created by Auto on 1/27/26.
//

import Foundation
import Combine

class PointHistoryViewModel: ObservableObject {
    @Published var pointHistory: [UserPoint] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var currentUserUuid: String? {
        didSet {
            if currentUserUuid != nil {
                loadPointHistory()
            }
        }
    }
    
    private let pointViewModel = PointViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    func loadPointHistory() {
        guard let userUuid = currentUserUuid else {
            return
        }
        
        isLoading = true
        
        pointViewModel.currentUserUuid = userUuid
        
        // 전체 포인트 내역 로드 (날짜 제한 없음)
        pointViewModel.loadUserPoints(
            startDate: nil,
            endDate: nil,
            pointUuid: nil,
            pointType: nil
        )
        
        // PointViewModel의 userPoints를 관찰
        pointViewModel.$userPoints
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userPoints in
                self?.pointHistory = userPoints
                self?.isLoading = false
            }
            .store(in: &cancellables)
        
        pointViewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
                if errorMessage != nil {
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
}

