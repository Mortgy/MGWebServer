//
//  Utils.swift
//  WebServer
//
//  Created by Mortgy on 6/2/24.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

#if canImport(UIKit)
import UIKit
#endif

func getIPAddress() -> String? {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    if getifaddrs(&ifaddr) == 0 {
        var ptr = ifaddr
        while ptr != nil {
            let interface = ptr?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                if let name = interface?.ifa_name {
                    let nameString = String(cString: name)
                    if nameString == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            address = String(cString: hostname)
                        }
                    }
                }
            }
            ptr = ptr?.pointee.ifa_next
        }
        freeifaddrs(ifaddr)
    }
    return address
}

func getDeviceType() -> String {
#if targetEnvironment(macCatalyst) || os(macOS)
    return "macOS"
#else
    switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "iOS"
        case .pad:
            return "iPadOS"
        case .mac:
            return "macOS"
        default:
            return "Unknown"
    }
#endif
}

func parseTXTRecord(data: Data) -> [String: String] {
    var result = [String: String]()
    let dict = NetService.dictionary(fromTXTRecord: data)
    
    for (key, value) in dict {
        if let valueData = value as Data?,
           let valueString = String(data: valueData, encoding: .utf8) {
            result[key] = valueString
        }
    }
    return result
}
