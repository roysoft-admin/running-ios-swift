//
//  WebView.swift
//  Running
//
//  Created by Auto on 1/23/26.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        // WKWebViewConfiguration 설정
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        
        // localStorage 활성화
        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController
        
        // 데이터 저장소 활성화
        let websiteDataStore = WKWebsiteDataStore.default()
        configuration.websiteDataStore = websiteDataStore
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .white
        
        // 초기 URL 저장 및 로드
        context.coordinator.lastLoadedURL = url
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        
        // 이미 같은 URL을 로드했거나 로드 중인 경우 아무것도 하지 않음
        if let lastURL = coordinator.lastLoadedURL, lastURL.absoluteString == url.absoluteString {
            // 같은 URL이고 로딩이 완료된 경우 로딩 상태를 false로 설정
            if !webView.isLoading {
                isLoading = false
            }
            return
        }
        
        // 현재 로딩 중이면 취소하지 않고 기다림
        if webView.isLoading {
            return
        }
        
        // URL이 변경되었고 로딩 중이 아닐 때만 새로 로드
        coordinator.lastLoadedURL = url
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        var lastLoadedURL: URL?
        
        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            // 페이지 로드가 시작되었지만 아직 완료되지 않음
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.isLoading = false
                // 로드 완료 시 현재 URL 저장
                if let url = webView.url {
                    self.lastLoadedURL = url
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // -999 오류는 요청 취소이므로 무시하고 로딩 상태만 업데이트
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled {
                // 취소된 경우 로딩 상태만 업데이트 (이미 다른 요청이 시작되었을 수 있음)
                DispatchQueue.main.async {
                    if !webView.isLoading {
                        self.isLoading = false
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            print("WebView 로드 실패: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            // -999 오류는 요청 취소이므로 무시하고 로딩 상태만 업데이트
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled {
                // 취소된 경우 로딩 상태만 업데이트 (이미 다른 요청이 시작되었을 수 있음)
                DispatchQueue.main.async {
                    if !webView.isLoading {
                        self.isLoading = false
                    }
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            print("WebView 프로비저널 로드 실패: \(error.localizedDescription)")
        }
    }
}

struct WebViewScreen: View {
    let urlString: String
    let title: String
    
    @State private var isLoading: Bool = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if let url = URL(string: urlString) {
                    WebView(url: url, isLoading: $isLoading)
                        .edgesIgnoringSafeArea(.bottom)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange500)
                        
                        Text("잘못된 URL입니다")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray700)
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    WebViewScreen(
        urlString: "https://www.apple.com",
        title: "약관"
    )
}


