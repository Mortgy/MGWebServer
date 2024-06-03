//
//  HTTPRequest.swift
//  MGWebServer
//
//  Created by Mortgy on 5/31/24.
//

import Foundation

public struct HTTPRequest {
    public let method: String
    public let path: String
    public let queryParameters: [String: String]
    public let headers: [String: String]
    public let body: Data?
    public var files: [String: (filename: String, data: Data)] = [:]
    
    public init?(data: Data) {
        guard let requestString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        let lines = requestString.split(separator: "\r\n")
        guard lines.count > 0 else {
            return nil
        }
        
        let requestLine = lines[0].split(separator: " ")
        guard requestLine.count == 3 else {
            return nil
        }
        
        self.method = String(requestLine[0])
        let urlString = String(requestLine[1])
        let urlComponents = URLComponents(string: urlString)
        self.path = urlComponents?.path ?? "/"
        self.queryParameters = HTTPRequest.parseQueryParameters(urlComponents?.query)
        
        var headers: [String: String] = [:]
        var bodyStartIndex = lines.count
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                bodyStartIndex = index + 1
                break
            }
            if index > 0 {
                let headerParts = line.split(separator: ":", maxSplits: 1)
                if headerParts.count == 2 {
                    let key = String(headerParts[0]).trimmingCharacters(in: .whitespaces)
                    let value = String(headerParts[1]).trimmingCharacters(in: .whitespaces)
                    headers[key] = value
                }
            }
        }
        
        self.headers = headers
        
        if bodyStartIndex < lines.count {
            let bodyLines = lines[bodyStartIndex..<lines.count]
            self.body = bodyLines.joined(separator: "\r\n").data(using: .utf8)
        } else {
            self.body = nil
        }
        
        if let contentType = headers["Content-Type"], contentType.contains("multipart/form-data") {
            if let boundary = contentType.components(separatedBy: "boundary=").last {
                self.files = HTTPRequest.parseMultipartFormData(data, boundary: boundary)
            }
        }
    }
    
    private static func parseQueryParameters(_ query: String?) -> [String: String] {
        var parameters: [String: String] = [:]
        query?.components(separatedBy: "&").forEach { component in
            let keyValue = component.split(separator: "=", maxSplits: 1).map { String($0) }
            if keyValue.count == 2 {
                parameters[keyValue[0]] = keyValue[1]
            }
        }
        return parameters
    }
    
    private static func parseMultipartFormData(_ data: Data, boundary: String) -> [String: (filename: String, data: Data)] {
        var files: [String: (filename: String, data: Data)] = [:]
        let boundaryData = "--\(boundary)".data(using: .utf8)!
        let boundaryEndData = "--\(boundary)--".data(using: .utf8)!
        
        var searchRange = data.startIndex..<data.endIndex
        
        while let boundaryRange = data.range(of: boundaryData, options: [], in: searchRange) {
            searchRange = boundaryRange.upperBound..<data.endIndex
            
            if let boundaryEndRange = data.range(of: boundaryEndData, options: [], in: searchRange) {
                searchRange = boundaryEndRange.upperBound..<data.endIndex
                break
            }
            
            if let endRange = data.range(of: boundaryData, options: [], in: searchRange) {
                searchRange = endRange.lowerBound..<data.endIndex
            }
            
            let partRange = boundaryRange.upperBound..<searchRange.lowerBound
            let partData = data[partRange]
            if let headersEndRange = partData.range(of: "\r\n\r\n".data(using: .utf8)!) {
                let headersData = partData[..<headersEndRange.lowerBound]
                let bodyData = partData[headersEndRange.upperBound...]
                
                if let dispositionHeader = String(data: headersData, encoding: .utf8)?.components(separatedBy: "\r\n").first(where: { $0.contains("Content-Disposition") }) {
                    if let nameRange = dispositionHeader.range(of: "name=\""), let filenameRange = dispositionHeader.range(of: "filename=\"") {
                        let nameEndIndex = dispositionHeader[nameRange.upperBound...].firstIndex(of: "\"") ?? dispositionHeader.endIndex
                        let filenameEndIndex = dispositionHeader[filenameRange.upperBound...].firstIndex(of: "\"") ?? dispositionHeader.endIndex
                        let name = String(dispositionHeader[nameRange.upperBound..<nameEndIndex])
                        let filename = String(dispositionHeader[filenameRange.upperBound..<filenameEndIndex])
                        
                        files[name] = (filename, Data(bodyData))
                    }
                }
            }
        }
        
        return files
    }
}
