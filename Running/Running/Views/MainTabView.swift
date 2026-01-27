//
//  MainTabView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .run:
                    RunView()
                case .report:
                    NavigationView {
                        ReportView()
                    }
                case .home:
                    NavigationView {
                        HomeView()
                    }
                case .shop:
                    ShopView()
                case .myPage:
                    NavigationView {
                        MyPageView()
                    }
                }
            }
            
            VStack {
                Spacer()
                
                BottomNavView(selectedTab: $appState.selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    MainTabView()
}


