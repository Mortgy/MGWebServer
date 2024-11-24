//
//  WebServer.swift
//  MGWebServer
//
//  Created by Mortgy on 5/31/24.
//

import Foundation
import Network

#if canImport(UIKit)
    import AVFoundation
    import UIKit
#endif

public class MGWebServer: NSObject {
    let configuration: MGWebServerConfiguration
    var listener: NWListener?
    private(set) var isRunning: Bool = false

    private let routeManager: RouteManager
    private let backgroundTaskManager: BackgroundTaskManager
    #if canImport(AVFoundation)
        private let audioPlaybackManager: AudioPlaybackManager
    #endif
    private let bonjourServiceManager: BonjourServiceManager
    private var requestHandler: RequestHandler!
    var backgroundURLSession: URLSession?

    public init(configuration: MGWebServerConfiguration) {
        self.configuration = configuration
        routeManager = RouteManager()
        backgroundTaskManager = BackgroundTaskManager(enableKeepAlive: configuration.enableKeepAlive)
        #if canImport(AVFoundation)
            audioPlaybackManager = AudioPlaybackManager(enableAudioPlayback: configuration.enableKeepAlive)
        #endif
        bonjourServiceManager = BonjourServiceManager()
        super.init()
        requestHandler = RequestHandler(routeManager: routeManager, server: self)
        setupBackgroundSession()
        #if canImport(UIKit)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        #endif
    }

    public func start(onStarted: ((Bool) -> Void)?) {
        routeManager.addRoute(path: "/ping") { _ in
            HTTPResponse(statusCode: 200, headers: ["Content-Type": "text/plain"], body: "Pong".data(using: .utf8))
        }
        startListener(onStarted: onStarted)
        if configuration.enableKeepAlive {
            backgroundTaskManager.startBackgroundTask { [weak self] in
                self?.sendKeepAlivePing()
            }
            #if canImport(AVFoundation)
                audioPlaybackManager.startAudioPlayback()
            #endif
        }
        if configuration.enableBonjour {
            bonjourServiceManager.publish(port: Int(configuration.port))
        }
        isRunning = true
    }

    public func stop() {
        stopListener()
        if configuration.enableBonjour {
            bonjourServiceManager.stop()
        }
        if configuration.enableKeepAlive {
            backgroundTaskManager.endBackgroundTask()
            #if canImport(AVFoundation)
                audioPlaybackManager.stopAudioPlayback()
            #endif
        }
        isRunning = false
    }

    public func isServerRunning() -> Bool {
        return isRunning
    }

    public func addRoute(path: String, handler: @escaping (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void) {
        routeManager.addAsyncRoute(path: path) { request, completion in
            handler(request) { response in
                completion(response)
            }
        }
    }

    public func addStaticRoute(forBasePath basePath: String, directoryPath: String) {
        routeManager.addStaticRoute(forBasePath: basePath, directoryPath: directoryPath)
    }

    private func startListener(onStarted: ((Bool) -> Void)?) {
        do {
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: configuration.port)!)
            listener?.stateUpdateHandler = { [weak self] newState in
                switch newState {
                case .ready:
                    print("Server ready on port \(self?.configuration.port ?? 0)")
                    if self?.configuration.enableBonjour == true {
                        self?.bonjourServiceManager.publish(port: Int(self?.configuration.port ?? 0))
                    }
                    onStarted?(true)
                case let .failed(error):
                    print("Server failed with error: \(error)")
                default:
                    break
                }
            }
            listener?.newConnectionHandler = { [weak self] newConnection in
                self?.requestHandler.handleConnection(newConnection)
            }
            listener?.start(queue: .main)
        } catch {
            print("Failed to start listener: \(error)")
        }
    }

    private func stopListener() {
        listener?.cancel()
        listener = nil
        print("Server stopped")
    }

    private func sendKeepAlivePing() {
        guard let url = URL(string: "http://localhost:\(configuration.port)/ping") else { return }
        let request = URLRequest(url: url)
        let task = backgroundURLSession?.dataTask(with: request)
        task?.resume()
    }

    @objc private func applicationDidEnterBackground() {
        if configuration.enableKeepAlive {
            backgroundTaskManager.startBackgroundTask { [weak self] in
                self?.sendKeepAlivePing()
            }
        }
    }

    @objc private func applicationWillEnterForeground() {
        if configuration.enableKeepAlive {
            backgroundTaskManager.endBackgroundTask()
        }
    }

    private func setupBackgroundSession() {
        let configuration = URLSessionConfiguration.background(withIdentifier: "\(String(describing: Bundle.main.bundleIdentifier)).MGWebServerBackground")
        backgroundURLSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
}

extension MGWebServer: URLSessionDelegate, URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
            sendKeepAlivePing()
        } else {
            print("Background task failed: \(error?.localizedDescription ?? "unknown error")")
        }
    }
}
