//
//  RouteManager.swift
//  WebServer
//
//  Created by Mortgy on 6/2/24.
//

import Foundation

public class RouteManager {
    private var routes: [String: (HTTPRequest) -> HTTPResponse] = [:]
    
    public init() {}
    
    public func addRoute(path: String, handler: @escaping (HTTPRequest) -> HTTPResponse) {
        routes[path] = handler
    }
    
    public func handleRequest(_ request: HTTPRequest) -> HTTPResponse {
        if let handler = routes[request.path] {
            return handler(request)
        } else {
            return HTTPResponse(statusCode: 404, headers: ["Content-Type": "text/plain"], body: "Not Found".data(using: .utf8))
        }
    }
    
    public func addStaticRoute(forBasePath basePath: String, directoryPath: String) {
        addRoute(path: basePath) { request in
            let filePath = (directoryPath as NSString).appendingPathComponent(request.path)
            if let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                let mimeType = self.mimeType(for: filePath)
                return HTTPResponse(statusCode: 200, headers: ["Content-Type": mimeType], body: fileData)
            } else {
                return HTTPResponse(statusCode: 404, headers: ["Content-Type": "text/plain"], body: "File Not Found".data(using: .utf8))
            }
        }
    }
    
    private func mimeType(for path: String) -> String {
        if path.hasSuffix(".html") {
            return "text/html"
        } else if path.hasSuffix(".css") {
            return "text/css"
        } else if path.hasSuffix(".js") {
            return "application/javascript"
        } else if path.hasSuffix(".png") {
            return "image/png"
        } else if path.hasSuffix(".jpg") {
            return "image/jpeg"
        } else if path.hasSuffix(".gif") {
            return "image/gif"
        } else {
            return "application/octet-stream"
        }
    }
}
