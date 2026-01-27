//
//  WebViewURL.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

enum WebViewURL {
    case terms          // 이용약관
    case privacy        // 개인정보처리방침
    case location       // 위치기반서비스 이용약관
    case purchase       // 구매 약관
    
    var urlString: String {
        // TODO: 실제 약관 URL은 여기 상수만 교체해서 사용
        switch self {
        case .terms:
            return TermsURL.terms
        case .privacy:
            return TermsURL.privacy
        case .location:
            return TermsURL.location
        case .purchase:
            return TermsURL.purchase
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
        case .purchase:
            return "구매 약관"
        }
    }
}

/// 약관 관련 URL 상수 모음 (필요할 때 여기만 실제 주소로 교체)
struct TermsURL {
    /// 이용약관 URL
    static let terms: String = "https://roysoft.co.kr"
    /// 개인정보처리방침 URL
    static let privacy: String = "https://roysoft.co.kr"
    /// 위치기반서비스 이용약관 URL
    static let location: String = "https://roysoft.co.kr"
    /// 구매 약관 URL
    static let purchase: String = "https://roysoft.co.kr"
}


