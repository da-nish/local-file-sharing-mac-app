//
//  Mac_Local_FileApp.swift
//  Mac_Local_File
//
//  Created by PropertyShare on 09/12/25.
//

import SwiftUI

@main
struct Mac_Local_FileApp: App {
    @StateObject private var webServer = WebServer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(webServer)
                .onAppear {
                    webServer.start()
                }
        }
    }
}
