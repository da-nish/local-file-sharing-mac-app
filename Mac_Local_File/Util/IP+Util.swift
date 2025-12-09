//
//  IP+Util.swift
//  Mac_Local_File
//
//  Created by PropertyShare on 09/12/25.
//


import SystemConfiguration

func getIP() -> String? {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>?

    if getifaddrs(&ifaddr) == 0 {
        var ptr = ifaddr
        while ptr != nil {
            let interface = ptr!.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            let name = String(cString: interface.ifa_name)

            // Wi-Fi = en0
            if name == "en0", addrFamily == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr,
                            socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            0,
                            NI_NUMERICHOST)
                address = String(cString: hostname)
            }
            ptr = interface.ifa_next
        }
        freeifaddrs(ifaddr)
    }
    return address
}
