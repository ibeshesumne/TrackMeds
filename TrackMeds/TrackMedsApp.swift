//
//  TrackMedsApp.swift
//  TrackMeds
//
//  Device-only version. No Firebase. Export/Import JSON and CSV support.
//

import SwiftUI

@main
struct TrackMedsApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .dynamicTypeSize(.xSmall ... .xxxLarge)
        }
    }
}
