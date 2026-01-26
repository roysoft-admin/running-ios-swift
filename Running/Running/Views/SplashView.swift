//
//  SplashView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct SplashView: View {
    @StateObject private var viewModel = SplashViewModel()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.gradientStart, Color.gradientEnd]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "figure.run")
                    .font(.system(size: 96, weight: .light))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(viewModel.showSplash ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 2.0)
                            .repeatForever(autoreverses: false),
                        value: viewModel.showSplash
                    )
                
                VStack(spacing: 8) {
                    Text("RunReward")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("달리고 보상받자")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .scaleEffect(viewModel.showSplash ? 1.0 : 0.5)
            .opacity(viewModel.showSplash ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.6), value: viewModel.showSplash)
        }
    }
}

#Preview {
    SplashView()
}


