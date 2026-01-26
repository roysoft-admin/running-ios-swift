//
//  WebViewURL.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

enum WebViewURL {
    case terms
    case privacy
    case location
    
    var urlString: String {
        // TODO: 실제 약관 URL 생성 필요
        switch self {
        case .terms:
            return "https://running.roysoft.co.kr/terms" // TODO: 실제 URL로 변경
        case .privacy:
            return "https://running.roysoft.co.kr/privacy" // TODO: 실제 URL로 변경
        case .location:
            return "https://running.roysoft.co.kr/location" // TODO: 실제 URL로 변경
        }
    }
    
    var title: String {
        switch self {
        case .terms:
            return "이용약관"
        case .privacy:
            return "개인정보처리방침"
        case .location:
            return "위치기반서비스 이용약관"
        }
    }
}


