//
//  TuftProjectClientApp.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/12.
//

import SwiftUI

@main
struct SimplestFullImmersionApp: App {
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState = AppState()
    @State private var speechService = SpeechService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(speechService)
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
//        .immersionStyle(selection: .constant(.full), in: .full)
        .onChange(of: scenePhase, initial: true) {
            if scenePhase != .active {
                if appState.immersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appState.immersiveSpaceOpened = false
                    }
                }
            }
        }
        .environment(speechService)
    }
}
