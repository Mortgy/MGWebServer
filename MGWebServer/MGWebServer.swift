//
//  WebServer.swift
//  MGWebServer
//
//  Created by Mortgy on 5/31/24.
//

import Foundation
import Network

#if canImport(UIKit)
import UIKit
import AVFoundation
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
    var backgroundURLSession: URLSession?
    
    public init(configuration: MGWebServerConfiguration) {
        self.configuration = configuration
        self.routeManager = RouteManager()
        self.backgroundTaskManager = BackgroundTaskManager()
#if canImport(AVFoundation)
        self.audioPlaybackManager = AudioPlaybackManager()
#endif
        self.bonjourServiceManager = BonjourServiceManager()
        super.init()
        setupBackgroundSession()
#if canImport(UIKit)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
#endif
    }
    
    public func start() {
        routeManager.addRoute(path: "/ping") { request in
            return HTTPResponse(statusCode: 200, headers: ["Content-Type": "text/plain"], body: "Pong".data(using: .utf8))
        }
        startListener()
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
    
    public func addRoute(path: String, handler: @escaping (HTTPRequest) -> HTTPResponse) {
        routeManager.addRoute(path: path, handler: handler)
    }
    
    public func addStaticRoute(forBasePath basePath: String, directoryPath: String) {
        routeManager.addStaticRoute(forBasePath: basePath, directoryPath: directoryPath)
    }
    
    private func startListener() {
        do {
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: configuration.port)!)
            listener?.stateUpdateHandler = { [weak self] (newState) in
                switch newState {
                    case .ready:
                        print("Server ready on port \(self?.configuration.port ?? 0)")
                        if self?.configuration.enableBonjour == true {
                            self?.bonjourServiceManager.publish(port: Int(self?.configuration.port ?? 0))
                        }
                    case .failed(let error):
                        print("Server failed with error: \(error)")
                    default:
                        break
                }
            }
            listener?.newConnectionHandler = { [weak self] newConnection in
                self?.handleConnection(newConnection)
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
    
    private func handleConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] (newState) in
            switch newState {
                case .ready:
                    print("Client connected: \(connection.endpoint)")
                    self?.receive(on: connection)
                case .failed(let error):
                    print("Client connection failed: \(error)")
                    connection.cancel()
                default:
                    break
            }
        }
        connection.start(queue: .main)
    }
    
    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                self?.handleRequest(data: data, on: connection)
            }
            if isComplete || error != nil {
                connection.cancel()
            } else {
                self?.receive(on: connection)
            }
        }
    }
    
    private func handleRequest(data: Data, on connection: NWConnection) {
        guard let request = HTTPRequest(data: data) else {
            let response = HTTPResponse(statusCode: 400, headers: ["Content-Type": "text/plain"], body: "Bad Request".data(using: .utf8))
            connection.send(content: response.buildResponse(), completion: .contentProcessed({ _ in
                connection.cancel()
            }))
            return
        }
        
        let response = routeManager.handleRequest(request)
        connection.send(content: response.buildResponse(), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
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
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.example.MGWebServerBackground")
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
