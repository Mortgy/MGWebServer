//
//  BonjourServiceManager.swift
//  WebServer
//
//  Created by Mortgy on 6/2/24.
//

import Foundation
import Network

#if canImport(UIKit)
import UIKit
#endif

public class BonjourServiceManager: NSObject {
    private var netService: NetService?
    
    public func publish(port: Int) {
#if canImport(UIKit)
        let serviceName = UIDevice.current.name
#else
        let serviceName = Host.current().localizedName ?? "Unknown"
#endif
        
        guard let ipAddress = Utils.getIPAddress() else {
            print("Failed to get IP address")
            return
        }
        let deviceType = Utils.getDeviceType()
        
        let txtRecord: [String: Data] = [
            "deviceType": deviceType.data(using: .utf8) ?? Data()
        ]
        
        netService = NetService(domain: "local.", type: "_mg-http._tcp.", name: serviceName, port: Int32(port))
        netService?.delegate = self
        netService?.setTXTRecord(NetService.data(fromTXTRecord: txtRecord))
        netService?.publish()
        
        print("Bonjour service published with IP: \(ipAddress) and device type: \(deviceType)")
    }
    
    public func getNetService() -> NetService?{
        return netService
    }
    
    public func stop() {
        netService?.stop()
        netService = nil
    }
}

extension BonjourServiceManager: NetServiceDelegate {
    public func netServiceDidPublish(_ sender: NetService) {
        print("Bonjour service published: domain=\(sender.domain) type=\(sender.type) name=\(sender.name) port=\(sender.port)")
    }
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("Failed to publish Bonjour service: \(errorDict)")
    }
}
