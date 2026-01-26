//
//  MainTabView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: BottomNavView.Tab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
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
                    NavigationView {
                        ShopView()
                    }
                case .myPage:
                    NavigationView {
                        MyPageView()
                    }
                }
            }
            
            VStack {
                Spacer()
                
                BottomNavView(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    MainTabView()
}


