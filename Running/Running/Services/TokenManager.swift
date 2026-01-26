//
//  TokenManager.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import Foundation

class TokenManager {
    static let shared = TokenManager()
    
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    
    private init() {}
    
    var accessToken: String? {
        get {
            return UserDefaults.standard.string(forKey: accessTokenKey)
        }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: accessTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: accessTokenKey)
            }
        }
    }
    
    var refreshToken: String? {
        get {
            return UserDefaults.standard.string(forKey: refreshTokenKey)
        }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: refreshTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: refreshTokenKey)
            }
        }
    }
    
    func saveTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
    }
    
    var isAuthenticated: Bool {
        return accessToken != nil
    }
}


