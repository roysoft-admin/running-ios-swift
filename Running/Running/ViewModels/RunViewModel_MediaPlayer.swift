//
//  RunViewModel_MediaPlayer.swift
//  Running
//
//  MediaPlayer를 사용한 Lock Screen 및 Control Center 표시
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit

extension RunViewModel {
    // MARK: - MediaPlayer Management (Lock Screen & Control Center)
    
    private var audioSession: AVAudioSession {
        return AVAudioSession.sharedInstance()
    }
    
    func setupMediaPlayer() {
        // 오디오 세션 설정 (백그라운드에서 작동하도록)
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("[RunViewModel] ✅ Audio session 활성화됨")
        } catch {
            print("[RunViewModel] ❌ Audio session 설정 실패: \(error.localizedDescription)")
        }
        
        // Remote Command Center 설정 (선택사항 - 일시정지/재개 버튼)
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 재생 버튼 (일시정지 상태일 때)
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self, self.isPaused else { return .commandFailed }
            self.resumeRunning()
            return .success
        }
        
        // 일시정지 버튼 (재생 중일 때)
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self, !self.isPaused else { return .commandFailed }
            self.pauseRunning()
            return .success
        }
        
        // 정지 버튼 비활성화 (러닝 중에는 정지 불가)
        commandCenter.stopCommand.isEnabled = false
    }
    
    func cleanupMediaPlayer() {
        // 오디오 세션 비활성화
        do {
            try audioSession.setActive(false)
            print("[RunViewModel] ✅ Audio session 비활성화됨")
        } catch {
            print("[RunViewModel] ❌ Audio session 비활성화 실패: \(error.localizedDescription)")
        }
        
        // Now Playing 정보 제거
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // Remote Command Center 비활성화
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
    }
    
    func updateNowPlayingInfo() {
        guard isRunning else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        let timeText = formatTime(time)
        let distanceText = String(format: "%.2f km", distance)
        let paceText = pace > 0 ? {
            let minutes = Int(pace / 60)
            let seconds = Int(pace.truncatingRemainder(dividingBy: 60))
            return String(format: "%d'%02d\"", minutes, seconds)
        }() : "--'--\""
        
        let statusText = isPaused ? "일시정지" : "러닝 중"
        let title = "\(statusText) • \(timeText)"
        let subtitle = "\(distanceText) • \(paceText)/km"
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: subtitle,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: time,
            MPMediaItemPropertyPlaybackDuration: time, // 현재 시간을 duration으로 설정
        ]
        
        // 앱 아이콘 추가 (선택사항)
        if let appIcon = UIImage(named: "AppIcon") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: appIcon.size) { _ in
                return appIcon
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        print("[RunViewModel] 📱 Now Playing 업데이트: \(title) - \(subtitle)")
    }
}
