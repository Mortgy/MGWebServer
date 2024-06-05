//
//  MGWebServerConf.swift
//  WebServer
//
//  Created by Mortgy on 6/2/24.
//

import Foundation

public struct MGWebServerConfiguration {
    let port: UInt16
    let enableKeepAlive: Bool
    let enableBonjour: Bool
    
    public init(port: UInt16, enableKeepAlive: Bool = false, enableBonjour: Bool = false) {
        self.port = port
        self.enableKeepAlive = enableKeepAlive
        self.enableBonjour = enableBonjour
    }
}


