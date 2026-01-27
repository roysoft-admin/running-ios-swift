//
//  PointHistoryView.swift
//  Running
//
//  Created by Auto on 1/27/26.
//

import SwiftUI

struct PointHistoryView: View {
    @StateObject private var viewModel = PointHistoryViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 200)
                } else if viewModel.pointHistory.isEmpty {
                    VStack(spacing: 16) {
                        Text("포인트 내역이 없습니다")
                            .font(.system(size: 16))
                            .foregroundColor(.gray500)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(viewModel.pointHistory) { item in
                        PointHistoryItemView(item: item)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 96) // 하단 탭바 공간 확보
        }
        .navigationTitle("포인트 내역")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.currentUserUuid = appState.currentUser?.uuid
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
    }
}

struct PointHistoryItemView: View {
    let item: UserPoint
    
    var body: some View {
        HStack(spacing: 16) {
            // Point Type Icon
            ZStack {
                Circle()
                    .fill(item.point?.type == .earned ? Color.emerald500.opacity(0.1) : Color.orange500.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: item.point?.type == .earned ? "plus.circle.fill" : "minus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(item.point?.type == .earned ? .emerald500 : .orange500)
            }
            
            // Point Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.point?.title ?? "포인트")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray900)
                
                Text(formatDate(item.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.gray500)
            }
            
            Spacer()
            
            // Point Amount
            Text("\(item.point?.type == .earned ? "+" : "-")\(item.pointAmount)P")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(item.point?.type == .earned ? .emerald500 : .orange500)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        return displayFormatter.string(from: date)
    }
}

