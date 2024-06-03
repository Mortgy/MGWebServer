//
//  BonjourService.swift
//  WebServer
//
//  Created by Mortgy on 6/2/24.
//

import Foundation

public struct BonjourService: Codable {
    public let name: String
    public let url: String
    public let ipAddress: String
    public let deviceType: String
    
    public init(name: String, url: String, ipAddress: String, deviceType: String) {
        self.name = name
        self.url = url
        self.ipAddress = ipAddress
        self.deviceType = deviceType
    }
}
