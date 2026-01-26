//
//  InquiryModalView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI
import Combine

struct InquiryModalView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = InquiryViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("문의 유형")) {
                    Picker("유형", selection: $viewModel.selectedType) {
                        ForEach(QNAType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section(header: Text("제목")) {
                    TextField("제목을 입력하세요", text: $viewModel.title)
                }
                
                Section(header: Text("내용")) {
                    TextEditor(text: $viewModel.text)
                        .frame(height: 200)
                }
                
                Section(header: Text("이메일")) {
                    TextField("이메일을 입력하세요", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("문의하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("전송") {
                        viewModel.submitInquiry {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            .errorAlert(errorMessage: $viewModel.errorMessage)
        }
    }
}

class InquiryViewModel: ObservableObject {
    @Published var selectedType: QNAType = .question
    @Published var title: String = ""
    @Published var text: String = ""
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let qnaService = QNAService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var canSubmit: Bool {
        !title.isEmpty && !text.isEmpty && !email.isEmpty && email.contains("@")
    }
    
    func submitInquiry(completion: @escaping () -> Void) {
        guard canSubmit else {
            errorMessage = "모든 항목을 입력해주세요"
            return
        }
        
        isLoading = true
        
        qnaService.createQNA(
            type: selectedType,
            title: title,
            text: text,
            email: email
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] result in
                self?.isLoading = false
                if case .failure(let error) = result {
                    self?.errorMessage = error.errorDescription
                }
            },
            receiveValue: { [weak self] _ in
                completion()
            }
        )
        .store(in: &cancellables)
    }
}

