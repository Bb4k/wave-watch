//
//  waveApp.swift
//  wave Watch App
//
//  Wave — the always-with-you companion for riding out craving waves.
//

import SwiftUI

@main
struct wave_Watch_AppApp: App {
    @StateObject private var store = WaveStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
