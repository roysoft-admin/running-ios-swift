//
//  RunViewModel_Notification.swift
//  Running
//
//  Notification 관련 확장
//

import Foundation
import UserNotifications

extension RunViewModel {
    // MARK: - Notification Management
    
    private func startNotification() {
        // Notification 권한 요청
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[RunViewModel] ❌ Notification 권한 요청 실패: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("[RunViewModel] ✅ Notification 권한 허용됨")
                DispatchQueue.main.async { [weak self] in
                    self?.updateNotification()
                    self?.startNotificationUpdateTimer()
                }
            } else {
                print("[RunViewModel] ⚠️ Notification 권한 거부됨")
            }
        }
    }
    
    private func stopNotification() {
        notificationUpdateTimer?.invalidate()
        notificationUpdateTimer = nil
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func startNotificationUpdateTimer() {
        notificationUpdateTimer?.invalidate()
        notificationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNotification()
        }
    }
    
    private func updateNotification() {
        guard isRunning else { return }
        
        let timeText = formatTime(time)
        let distanceText = String(format: "%.2f km", distance)
        let paceText = pace > 0 ? {
            let minutes = Int(pace / 60)
            let seconds = Int(pace.truncatingRemainder(dividingBy: 60))
            return String(format: "%d'%02d\"", minutes, seconds)
        }() : "--'--\""
        
        let statusText = isPaused ? "일시정지" : "러닝 중"
        let contentText = "\(distanceText) • \(paceText)/km"
        
        let content = UNMutableNotificationContent()
        content.title = "\(statusText) • \(timeText)"
        content.body = contentText
        content.sound = nil // 소리 없음
        content.badge = nil
        
        let request = UNNotificationRequest(
            identifier: "running-notification",
            content: content,
            trigger: nil // 즉시 표시
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[RunViewModel] ❌ Notification 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }
}
