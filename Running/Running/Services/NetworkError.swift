//
//  NetworkError.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int, String?)
    case unauthorized
    case tokenExpired
    case networkError(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다."
        case .noData:
            return "데이터를 받을 수 없습니다."
        case .decodingError(let error):
            return "데이터 파싱 오류: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return message ?? "서버 오류가 발생했습니다. (코드: \(code))"
        case .unauthorized:
            return "인증이 필요합니다."
        case .tokenExpired:
            return "토큰이 만료되었습니다. 다시 로그인해주세요."
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}


