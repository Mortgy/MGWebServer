//
//  BackgroundTaskManager.swift
//  WebServer
//
//  Created by Mortgy on 6/2/24.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

public class BackgroundTaskManager {
    private var enableKeepAlive: Bool
    
    #if canImport(UIKit)
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var keepAliveWorkItem: DispatchWorkItem?
    
    public init(enableKeepAlive: Bool) {
        self.enableKeepAlive = enableKeepAlive
    }
    
    public func startBackgroundTask(keepAlive: @escaping () -> Void) {
        guard enableKeepAlive else { return }
        
        if backgroundTask != .invalid {
            endBackgroundTask()
        }
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "MGWebServerBackgroundTask") {
            self.endBackgroundTask()
        }
        keepAliveWorkItem = DispatchWorkItem {
            self.keepAliveLoop(keepAlive: keepAlive)
        }
        if let keepAliveWorkItem = keepAliveWorkItem {
            DispatchQueue.global().async(execute: keepAliveWorkItem)
        }
    }
    
    public func endBackgroundTask() {
        guard enableKeepAlive else { return }
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        keepAliveWorkItem?.cancel()
        keepAliveWorkItem = nil
    }
    
    private func keepAliveLoop(keepAlive: @escaping () -> Void) {
        while UIApplication.shared.backgroundTimeRemaining > 1 {
            sleep(10)
            keepAlive()
        }
        endBackgroundTask()
    }
    #else
    public init(enableKeepAlive: Bool) {
        self.enableKeepAlive = enableKeepAlive
    }
    
    public func startBackgroundTask(keepAlive: @escaping () -> Void) {
        // No-op for macOS
        guard enableKeepAlive else { return }
        keepAlive()
    }
    
    public func endBackgroundTask() {
        // No-op for macOS
    }
    #endif
}
