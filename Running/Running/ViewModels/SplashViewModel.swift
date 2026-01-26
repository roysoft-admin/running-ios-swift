//
//  SplashViewModel.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation
import Combine

class SplashViewModel: ObservableObject {
    @Published var showSplash: Bool = true
    
    init() {
        // 2초 후 스플래시 화면 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showSplash = false
        }
    }
}


