//
//  WispApp.swift
//  Wisp
//
//  Created by Ege Hurturk on 14.07.2025.
//

import SwiftUI

@main
struct WispApp: App {
    private let logger = Logger.general
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    logger.info("Wisp app launched successfully")
                }
        }
    }
}
