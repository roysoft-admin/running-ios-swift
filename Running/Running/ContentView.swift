//
//  ContentView.swift
//  Running
//
//  Created by Ryan on 1/23/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    @State private var showSignUp: Bool = false

    var body: some View {
        Group {
            if appState.showSplash || appState.isCheckingAuth {
                // 스플래시 화면 또는 자동 로그인 체크 중
                SplashView()
            } else if !appState.isLoggedIn {
                // 로그인 화면
                LoginView(isLoggedIn: $appState.isLoggedIn)
                    .sheet(isPresented: $showSignUp) {
                        SignUpView(isSignedUp: $appState.isLoggedIn)
                    }
            } else {
                // 메인 화면
                MainTabView()
                    .environmentObject(appState)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
