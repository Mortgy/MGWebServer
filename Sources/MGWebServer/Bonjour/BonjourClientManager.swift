//
//  BonjourClientManager.swift
//  WebServer
//
//  Created by Mortgy on 6/2/24.
//

import Foundation

public class BonjourClientManager: NSObject {
    private var netServiceBrowser: NetServiceBrowser?
    private var discoveredServices: [NetService] = []
    private var servicesCallback: (([BonjourService]) -> Void)?
    
    public func startBrowsing(callback: @escaping ([BonjourService]) -> Void) {
        servicesCallback = callback
        netServiceBrowser = NetServiceBrowser()
        netServiceBrowser?.delegate = self
        netServiceBrowser?.searchForServices(ofType: "_mg-http._tcp.", inDomain: "local.")
    }
    
    public func stopBrowsing() {
        netServiceBrowser?.stop()
        netServiceBrowser = nil
        discoveredServices.removeAll()
    }
    
    private func updateDiscoveredServices() {
        var servicesInfo: [BonjourService] = []
        for service in discoveredServices {
            if let hostName = service.hostName  {
                let urlString = "http://\(hostName):\(service.port)"
                let txtRecord = service.txtRecordData().flatMap { parseTXTRecord(data: $0) }
                let deviceType = txtRecord?["deviceType"] ?? "Unknown"
                let bonjourService = BonjourService(name: service.name, url: urlString, ipAddress: hostName, deviceType: deviceType)
                servicesInfo.append(bonjourService)
            }
        }
        servicesCallback?(servicesInfo)
    }
}

extension BonjourClientManager: NetServiceBrowserDelegate {
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Discovered service: \(service)")
        discoveredServices.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5)
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("Service removed: \(service)")
        if let index = discoveredServices.firstIndex(of: service) {
            discoveredServices.remove(at: index)
            updateDiscoveredServices()
        }
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("Failed to search for services: \(errorDict)")
    }
}

extension BonjourClientManager: NetServiceDelegate {
    public func netServiceDidResolveAddress(_ sender: NetService) {
        updateDiscoveredServices()
    }
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Failed to resolve service: \(errorDict)")
    }
}
