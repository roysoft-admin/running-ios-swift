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
    
    func startNotification() {
        // MediaPlayer 설정 (Lock Screen & Control Center)
        setupMediaPlayer()
        
        // Notification 권한 요청 (백그라운드에서 앱을 다시 열 때를 위해)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[RunViewModel] ❌ Notification 권한 요청 실패: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("[RunViewModel] ✅ Notification 권한 허용됨")
                DispatchQueue.main.async { [weak self] in
                    // 러닝 시작 시 한 번만 노티 표시
                    self?.updateNotification()
                    // Lock Screen & Control Center는 startTimer()에서 매초 업데이트됨
                    self?.updateNowPlayingInfo()
                }
            } else {
                print("[RunViewModel] ⚠️ Notification 권한 거부됨")
                // 권한이 거부되어도 MediaPlayer는 작동함
                DispatchQueue.main.async { [weak self] in
                    self?.updateNowPlayingInfo()
                }
            }
        }
    }
    
    func stopNotification() {
        notificationUpdateTimer?.invalidate()
        notificationUpdateTimer = nil
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // MediaPlayer 정리 (Lock Screen & Control Center에서 제거)
        cleanupMediaPlayer()
    }
    
    func updateNotification() {
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
        
        // 같은 identifier의 알림을 제거하고 새로 추가 (더 효율적)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ["running-notification"])
        
        let request = UNNotificationRequest(
            identifier: "running-notification",
            content: content,
            trigger: nil // 즉시 표시
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("[RunViewModel] ❌ Notification 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }
}
