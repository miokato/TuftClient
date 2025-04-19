//
//  ContentView.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/12.
//

import SwiftUI
import RealityKit
import RealityKitContent

import SwiftUI

struct ContentView: View {
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SpeechService.self) private var speechService
    @AppStorage("threadId") var threadId: String = ""
    
    private func createThread() {
        Task {
            do {
                print(threadId)
//                guard threadId == "" else {
//                    return
//                }
                // thread 作成
                let res = try await APIService.shared.createThread()
                threadId = res.id
                print("Create thread : \(threadId)")
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    private func sendMessage() {
        guard let text = speechService.recognizedText else {
            print("No text recognized")
            return
        }
        Task {
            do {
                guard let res = try await APIService.shared.sendMessage(id: threadId, message: text) else { return }
                print("Receive message : \(res)")
                speechService.textToSpeech(text: res.content)
            } catch {
                print("Error: \(error)")
            }
        }
    }

    var body: some View {
        VStack {
            Button("Open Immersive Space") {
                Task {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        break
                    case .userCancelled:
                        break
                    case .error:
                        break
                    @unknown default:
                        break
                    }
                }
            }
            Button("Start voice Recording") {
                speechService.startSpeechToText()
            }
            Button("Stop voice recording") {
                speechService.stopSpeechToText()
                sendMessage()
            }
        }
        .onAppear {
            createThread()
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(SpeechService())
}
