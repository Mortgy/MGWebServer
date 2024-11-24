//
//  RouteManager.swift
//  WebServer
//
//  Created by Mortgy on 6/2/24.
//

import Foundation

public class RouteManager {
    // Updated to support both synchronous and asynchronous routes
    private var routes: [String: (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void] = [:]

    public init() {}

    // Add a synchronous route
    public func addRoute(path: String, handler: @escaping (HTTPRequest) -> HTTPResponse) {
        routes[path] = { request, completion in
            let response = handler(request)
            completion(response) // Convert sync handler to async-compatible
        }
    }

    // Add an asynchronous route
    public func addAsyncRoute(path: String, handler: @escaping (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void) {
        routes[path] = handler
    }

    // Handle an incoming request
    public func handleRequest(_ request: HTTPRequest, completion: @escaping (HTTPResponse) -> Void) {
        if let handler = routes[request.path] {
            handler(request, completion)
        } else {
            let notFoundResponse = HTTPResponse(
                statusCode: 404,
                headers: ["Content-Type": "text/plain"],
                body: "Not Found".data(using: .utf8)
            )
            completion(notFoundResponse)
        }
    }

    // Add static routes
    public func addStaticRoute(forBasePath basePath: String, directoryPath: String) {
        addRoute(path: basePath) { request in
            let filePath = (directoryPath as NSString).appendingPathComponent(request.path)
            if let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                let mimeType = self.mimeType(for: filePath)
                return HTTPResponse(statusCode: 200, headers: ["Content-Type": mimeType], body: fileData)
            } else {
                return HTTPResponse(
                    statusCode: 404,
                    headers: ["Content-Type": "text/plain"],
                    body: "File Not Found".data(using: .utf8)
                )
            }
        }
    }

    // Determine MIME type
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
