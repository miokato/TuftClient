//
//  ImmersiveView.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/12.
//

import SwiftUI
import RealityKit
import ARKit

struct ImmersiveView: View {
    @AppStorage("threadId") var threadId: String = ""
    @Environment(SpeechService.self) private var speechService
    private let appManager = AppManager()
    
    private func fetchThreadId() {
        Task {
            do {
                let r = try await APIService.shared.createThread()
                threadId = r.id
            } catch {
                print(error)
            }
        }
    }
    
    var body: some View {
        RealityView { content, attachments in
            content.add(appManager.rootEntity)
        } update: { content, attachments in
            // update
        } attachments: {
            // contents
        }
        .task {
            await appManager.run()
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { event in
                    print("tapped")
                    let location = event.location
                    print("location: \(location)")
                }
        )
        .onAppear {
            print("on appear")
        }
        .task {
            speechService.textToSpeech(text: "やぁ元気？")
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(SpeechService())
}
