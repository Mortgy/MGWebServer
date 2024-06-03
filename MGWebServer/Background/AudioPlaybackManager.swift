//
//  AudioPlaybackManager.swift
//  WebServer
//
//  Created by Mortgy on 6/2/24.
//

#if canImport(AVFoundation)
import AVFoundation
#endif

public class AudioPlaybackManager {
#if canImport(AVFoundation) && canImport(AVAudioSession)
    private var audioPlayer: AVAudioPlayer?
    
    public init() {
        setupAudioSession()
    }
    
    public func startAudioPlayback() {
        let frameworkBundle = Bundle(for: type(of: self))
        guard let audioPath = frameworkBundle.path(forResource: "silent", ofType: "mp3") else {
            print("Silent audio file not found in the framework bundle")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioPath))
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.play()
        } catch {
            print("Failed to initialize audio player: \(error)")
        }
    }
    
    public func stopAudioPlayback() {
        audioPlayer?.stop()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
#else
    // No-op implementations for macOS
    public init() {}
    
    public func startAudioPlayback() {
        // No-op
    }
    
    public func stopAudioPlayback() {
        // No-op
    }
#endif
}
