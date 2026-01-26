//
//  BottomNavView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct BottomNavView: View {
    @Binding var selectedTab: Tab
    
    enum Tab: String, CaseIterable {
        case run = "Run"
        case report = "Report"
        case home = "Home"
        case shop = "Shop"
        case myPage = "My"
        
        var icon: String {
            switch self {
            case .run: return "figure.run"
            case .report: return "chart.bar"
            case .home: return "house.fill"
            case .shop: return "bag.fill"
            case .myPage: return "person.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == tab ? Color.emerald500 : Color.gray500)
                        
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == tab ? Color.emerald500 : Color.gray500)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(height: 60)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray200),
            alignment: .top
        )
    }
}

#Preview {
    BottomNavView(selectedTab: .constant(.home))
}


