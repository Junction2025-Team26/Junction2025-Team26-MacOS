//
//  SyncTankApp.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

@main
struct SyncTankApp: App {
    var body: some Scene {
        Window("SyncTank", id: "main") {
            MainInsightView()
        }
        .defaultSize(width: 420, height: 120)
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        //Hidden해야 가려짐
        .windowStyle(.hiddenTitleBar)
    }
}
