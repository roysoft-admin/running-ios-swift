//
//  PurchaseView.swift
//  Running
//
//  Created by Auto on 1/27/26.
//

import SwiftUI

struct PurchaseView: View {
    @StateObject var viewModel: PurchaseViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Product Info Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("상품 정보")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray900)
                    
                    HStack(spacing: 16) {
                        // Product Image
                        if let imageUrl = viewModel.shopItem.imageUrl, !imageUrl.isEmpty {
                            let fullUrl = imageUrl.hasPrefix("http") ? imageUrl : "http://localhost:3031\(imageUrl.hasPrefix("/") ? imageUrl : "/\(imageUrl)")"
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
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.shopItem.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray900)
                                .lineLimit(2)
                            
                            Text("\(NumberFormatter.numberFormatter.string(from: NSNumber(value: viewModel.shopItem.point)) ?? "0")P")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.emerald500)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray50)
                    .cornerRadius(16)
                }
                
                // Points Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("포인트 정보")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray900)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("보유 포인트")
                                .font(.system(size: 14))
                                .foregroundColor(.gray700)
                            Spacer()
                            Text("\(NumberFormatter.numberFormatter.string(from: NSNumber(value: viewModel.currentPoints)) ?? "0")P")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray900)
                        }
                        
                        HStack {
                            Text("사용 포인트")
                                .font(.system(size: 14))
                                .foregroundColor(.gray700)
                            Spacer()
                            Text("-\(NumberFormatter.numberFormatter.string(from: NSNumber(value: viewModel.shopItem.point)) ?? "0")P")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("남은 포인트")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.gray900)
                            Spacer()
                            Text("\(NumberFormatter.numberFormatter.string(from: NSNumber(value: viewModel.remainingPoints)) ?? "0")P")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.emerald500)
                        }
                    }
                    .padding()
                    .background(Color.gray50)
                    .cornerRadius(16)
                }
                
                // Phone Verification Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("전화번호 인증")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray900)
                    
                    VStack(spacing: 12) {
                        // Phone Number Input
                        HStack(spacing: 12) {
                            TextField("전화번호를 입력하세요", text: $viewModel.phoneNumber)
                                .keyboardType(.phonePad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(viewModel.isCodeSent)
                            
                            Button(action: {
                                viewModel.sendVerificationCode()
                            }) {
                                Text(viewModel.isCodeSent ? "재발송" : "인증번호 발송")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(viewModel.phoneNumber.isEmpty ? Color.gray400 : Color.emerald500)
                                    .cornerRadius(8)
                            }
                            .disabled(viewModel.phoneNumber.isEmpty || (viewModel.isCodeSent && viewModel.countdown > 0))
                        }
                        
                        if viewModel.isCodeSent {
                            // Verification Code Input
                            HStack(spacing: 12) {
                                TextField("인증번호 6자리", text: $viewModel.verificationCode)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(viewModel.isVerified)
                                
                                if viewModel.countdown > 0 {
                                    Text("\(viewModel.countdown / 60):\(String(format: "%02d", viewModel.countdown % 60))")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray600)
                                        .frame(width: 60)
                                }
                                
                                Button(action: {
                                    viewModel.verifyCode()
                                }) {
                                    Text(viewModel.isVerified ? "인증완료" : "인증하기")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(viewModel.isVerified ? Color.gray400 : (viewModel.verificationCode.count == 6 ? Color.emerald500 : Color.gray400))
                                        .cornerRadius(8)
                                }
                                .disabled(viewModel.isVerified || viewModel.verificationCode.count != 6)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray50)
                    .cornerRadius(16)
                }
                
                // Agreement Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("구매 약관 동의")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray900)
                    
                    VStack(spacing: 12) {
                        AgreementRow(
                            title: "구매 약관 동의 (필수)",
                            isAgreed: $viewModel.agreedPurchase,
                            showViewButton: true
                        )
                    }
                }
                
                // Purchase Button
                Button(action: {
                    viewModel.purchase()
                }) {
                    Text("구매하기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.canPurchase ? Color.emerald500 : Color.gray400)
                        .cornerRadius(16)
                }
                .disabled(!viewModel.canPurchase)
            }
            .padding(24)
            .padding(.bottom, 96) // 하단 탭바 공간 확보
        }
        .navigationTitle("상품 구매")
        .navigationBarTitleDisplayMode(.inline)
        .alert("에러", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("구매 완료", isPresented: $viewModel.purchaseSuccess) {
            Button("확인") {
                dismiss()
            }
        } message: {
            Text("상품 구매가 완료되었습니다.")
        }
        .onAppear {
            viewModel.currentUserUuid = appState.currentUser?.uuid
        }
    }
}

extension NumberFormatter {
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

