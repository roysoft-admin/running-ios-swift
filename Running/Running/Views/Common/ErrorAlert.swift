//
//  ErrorAlert.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI

struct ErrorAlert: ViewModifier {
    @Binding var errorMessage: String?
    
    func body(content: Content) -> some View {
        content
            .alert("오류", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let message = errorMessage {
                    Text(message)
                }
            }
    }
}

extension View {
    func errorAlert(errorMessage: Binding<String?>) -> some View {
        modifier(ErrorAlert(errorMessage: errorMessage))
    }
}

