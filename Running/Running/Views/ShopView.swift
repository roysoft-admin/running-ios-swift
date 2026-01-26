//
//  ShopView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("포인트 샵")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray900)
                    
                    // Points Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("보유 포인트")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack(spacing: 8) {
                                Image(systemName: "bitcoinsign.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                
                                Text("\(viewModel.currentPoints)P")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        Button("히스토리") {
                            // TODO: 히스토리 화면으로 이동
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding(16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gradientStart, Color.gradientEnd]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(16)
                .background(Color.white)
                
                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([ShopItem.ProductCategory.all, .fnb, .voucher, .coupon, .culture], id: \.self) { category in
                            CategoryButton(
                                title: category.rawValue,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                .background(Color.white)
                
                // Products Grid
                if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 200)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(viewModel.filteredProducts) { shopItem in
                            ProductCard(product: shopItem) {
                                viewModel.purchaseProduct(shopItem)
                            }
                        }
                    }
                    .padding(16)
                }
                
                // Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color.blue500)
                        
                        Text("📌 상품 사용 안내")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.blue500)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 구매한 상품은 취소가 불가능합니다")
                        Text("• 상품은 구매 후 3일 이내에 발송됩니다")
                        Text("• 이메일로 상품권 코드가 전송됩니다")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color.blue500.opacity(0.8))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue50)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue200, lineWidth: 1)
                )
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color.gray50)
        .loadingOverlay(isLoading: $viewModel.isLoading)
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .alert("구매 완료", isPresented: $viewModel.purchaseSuccess) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("상품 구매가 완료되었습니다.")
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray600)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.emerald500 : Color.gray100)
                .cornerRadius(20)
        }
    }
}

struct ProductCard: View {
    let product: ShopItem
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Product Image
            ZStack {
                Color.gray100
                
                Text(product.image)
                    .font(.system(size: 48))
            }
            .frame(height: 160)
            
            // Product Info
            VStack(alignment: .leading, spacing: 8) {
                Text(product.category.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.emerald500)
                
                Text(product.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray900)
                    .lineLimit(2)
                    .frame(height: 40, alignment: .top)
                
                HStack {
                    Text("\(product.point)P")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.emerald500)
                    
                    Spacer()
                    
                    Button(action: action) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.emerald500)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ShopView()
}

