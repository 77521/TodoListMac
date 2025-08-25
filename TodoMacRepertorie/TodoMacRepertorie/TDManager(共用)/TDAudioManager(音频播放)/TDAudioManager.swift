//
//  TDAudioManager.swift
//  TodoMacRepertorie
//
//  Created by Assistant on 2025/1/20.
//

import Foundation
import AppKit

/// 音频管理器（macOS 版本）
class TDAudioManager: NSObject {
    static let shared = TDAudioManager()
    
    private var currentSound: NSSound?
    
    private override init() {
        super.init()
    }
    
    /// 播放音频文件（播放一次）
    /// - Parameter fileName: 音频文件名（包含扩展名）
    func playAudio(fileName: String) {
        playAudio(fileName: fileName, loop: false)
    }
    
    /// 播放音频文件
    /// - Parameters:
    ///   - fileName: 音频文件名（包含扩展名）
    ///   - loop: 是否循环播放
    func playAudio(fileName: String, loop: Bool) {
        // 停止当前播放
        stopAudio()
        
        // 获取音频文件路径
        guard let audioURL = getAudioURL(fileName: fileName) else {
            print("找不到音频文件: \(fileName)")
            return
        }
        
        // 创建 NSSound 实例
        currentSound = NSSound(contentsOf: audioURL, byReference: false)
        
        guard let sound = currentSound else {
            print("创建音频播放器失败: \(fileName)")
            return
        }
        
        // 设置循环播放
        sound.loops = loop
        
        // 开始播放（不占用其他应用的音频）
        if sound.play() {
            print("开始播放音频: \(fileName), 循环: \(loop)")
        } else {
            print("播放音频失败: \(fileName)")
        }
    }
    
    /// 播放完成音效
    func playCompletionSound() {
        // 检查是否开启音效
        guard TDSettingManager.shared.enableSound else {
            return
        }
        
        // 播放指定音效
        playAudio(fileName: TDSettingManager.shared.soundType.fileName)
    }

    /// 停止音频播放
    func stopAudio() {
        currentSound?.stop()
        currentSound = nil
    }
    
    /// 检查是否正在播放
    var isPlaying: Bool {
        return currentSound?.isPlaying == true
    }
    
    // MARK: - 私有方法
    
    /// 获取音频文件URL
    /// - Parameter fileName: 音频文件名
    /// - Returns: 音频文件URL
    private func getAudioURL(fileName: String) -> URL? {
        // 首先尝试从 Bundle 中获取
        if let bundleURL = Bundle.main.url(forResource: fileName.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") {
            return bundleURL
        }
        
        // 如果 Bundle 中没有，尝试从 Documents 目录获取
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let audioURL = documentsPath?.appendingPathComponent(fileName)
        
        // 检查文件是否存在
        if let url = audioURL, FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        
        return nil
    }
}
