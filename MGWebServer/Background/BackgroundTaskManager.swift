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
#if canImport(UIKit)
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var keepAliveWorkItem: DispatchWorkItem?
    
    public func startBackgroundTask(keepAlive: @escaping () -> Void) {
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
    public func startBackgroundTask(keepAlive: @escaping () -> Void) {
        // No-op for macOS
        keepAlive()
    }
    
    public func endBackgroundTask() {
        // No-op for macOS
    }
#endif
}
