//
//  SocialLoginButton.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct SocialLoginButton: View {
    let provider: SocialProvider
    let action: () -> Void
    
    enum SocialProvider {
        case google
        case apple
        case kakao
        case naver
        case facebook
        
        var title: String {
            switch self {
            case .google: return "Google로 계속하기"
            case .apple: return "Apple로 계속하기"
            case .kakao: return "카카오로 계속하기"
            case .naver: return "네이버로 계속하기"
            case .facebook: return "Facebook으로 계속하기"
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .google: return .white
            case .apple: return .black
            case .kakao: return Color(red: 1.0, green: 0.898, blue: 0.0) // #FEE500
            case .naver: return Color(red: 0.012, green: 0.780, blue: 0.353) // #03C75A
            case .facebook: return Color.gray100
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .google: return .gray900
            case .apple: return .white
            case .kakao: return .gray900
            case .naver: return .white
            case .facebook: return .gray700
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .google: return Color.gray200
            case .apple: return nil
            case .kakao: return nil
            case .naver: return nil
            case .facebook: return nil
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(provider.foregroundColor)
                
                Text(provider.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(provider.foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(provider.backgroundColor)
            .overlay(
                Group {
                    if let borderColor = provider.borderColor {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 2)
                    }
                }
            )
            .cornerRadius(16)
        }
    }
    
    private var iconName: String {
        switch provider {
        case .google: return "globe"
        case .apple: return "applelogo"
        case .kakao: return "person.circle"
        case .naver: return "n.circle.fill"
        case .facebook: return "f.circle.fill"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SocialLoginButton(provider: .google, action: {})
        SocialLoginButton(provider: .apple, action: {})
        SocialLoginButton(provider: .kakao, action: {})
        SocialLoginButton(provider: .naver, action: {})
    }
    .padding()
}

