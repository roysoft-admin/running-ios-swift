//
//  LoadingOverlay.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct LoadingOverlay: ViewModifier {
    @Binding var isLoading: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("로딩 중...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray900.opacity(0.9))
                )
            }
        }
    }
}

extension View {
    func loadingOverlay(isLoading: Binding<Bool>) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading))
    }
}


