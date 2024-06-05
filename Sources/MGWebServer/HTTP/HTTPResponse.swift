//
//  HTTPResponse.swift
//  MGWebServer
//
//  Created by Mortgy on 5/31/24.
//

import Foundation

public struct HTTPResponse {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?
    
    public init(statusCode: Int, headers: [String: String], body: Data?) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
    
    public func buildResponse() -> Data {
        var response = "HTTP/1.1 \(statusCode) \(statusDescription())\r\n"
        for (key, value) in headers {
            response += "\(key): \(value)\r\n"
        }
        response += "\r\n"
        var responseData = response.data(using: .utf8) ?? Data()
        if let body = body {
            responseData.append(body)
        }
        return responseData
    }
    
    private func statusDescription() -> String {
        switch statusCode {
            case 200: return "OK"
            case 400: return "Bad Request"
            case 404: return "Not Found"
            case 500: return "Internal Server Error"
            default: return "Unknown"
        }
    }
}

