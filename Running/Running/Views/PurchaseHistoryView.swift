//
//  PurchaseHistoryView.swift
//  Running
//
//  Created by Auto on 1/27/26.
//

import SwiftUI

struct PurchaseHistoryView: View {
    @StateObject private var viewModel = PurchaseHistoryViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 200)
                } else if viewModel.purchaseHistory.isEmpty {
                    VStack(spacing: 16) {
                        Text("구매 내역이 없습니다")
                            .font(.system(size: 16))
                            .foregroundColor(.gray500)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(viewModel.purchaseHistory) { item in
                        PurchaseHistoryItemView(item: item)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 96) // 하단 탭바 공간 확보
        }
        .navigationTitle("구매 내역")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.currentUserUuid = appState.currentUser?.uuid
        }
        .alert("에러", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct PurchaseHistoryItemView: View {
    let item: UserShopItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Product Image
            if let imageUrl = item.shopItem?.imageUrl, !imageUrl.isEmpty {
                let fullUrl = imageUrl.hasPrefix("http") ? imageUrl : "https://running.roysoft.co.kr\(imageUrl.hasPrefix("/") ? imageUrl : "/\(imageUrl)")"
                AsyncImage(url: URL(string: fullUrl)) { phase in
                    switch phase {
                    case .empty:
                        Color.clear
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.clear
                    @unknown default:
                        Color.clear
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                .clipped()
            } else {
                Color.clear
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.shopItem?.name ?? "상품 정보 없음")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray900)
                
                Text("\(NumberFormatter.numberFormatter.string(from: NSNumber(value: item.shopItem?.point ?? 0)) ?? "0")P")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.emerald500)
                
                // Purchase Date
                Text(formatDate(item.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.gray500)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy.MM.dd"
        return displayFormatter.string(from: date)
    }
}

