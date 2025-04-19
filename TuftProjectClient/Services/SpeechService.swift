//
//  SpeechService.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/12.
//
import Observation
import Speech
import AVFoundation

@Observable
final class SpeechService: NSObject {
    // speech
    @ObservationIgnored private var speechRecognizer: SFSpeechRecognizer?
    @ObservationIgnored private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var recognitionTask: SFSpeechRecognitionTask?
    // audio
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private var inputNode: AVAudioInputNode?
    @ObservationIgnored private var audioSession: AVAudioSession?
    
    var recognizedText: String?
    var isProcessing: Bool = false
    
    @ObservationIgnored private let speechSynthesizer = AVSpeechSynthesizer()
    
    /// テキストを渡して会話させる
    func textToSpeech(text: String, language: String = "ja-JP") {
        guard let voice = AVSpeechSynthesisVoice(language: language) else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    /// 音声認識を開始する
    func startSpeechToText() {
        guard !isProcessing else { return }
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Couldn't configure the audio session properly")
        }
        
        inputNode = audioEngine.inputNode
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
        print("Supports on device recognition: \(speechRecognizer?.supportsOnDeviceRecognition == true ? "✅" : "🔴")")
        
        // Force specified locale
        // self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pl_PL"))
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Disable partial results
        // recognitionRequest?.shouldReportPartialResults = false
        
        // Enable on-device recognition
        // recognitionRequest?.requiresOnDeviceRecognition = true
        
        guard let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable,
              let recognitionRequest = recognitionRequest,
              let inputNode = inputNode
        else {
            assertionFailure("Unable to start the speech recognition!")
            return
        }
        
        speechRecognizer.delegate = self
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            recognitionRequest.append(buffer)
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            self?.recognizedText = result?.bestTranscription.formattedString
            
            guard error != nil || result?.isFinal == true else { return }
            self?.stopSpeechToText()
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isProcessing = true
        } catch {
            print("Coudn't start audio engine!")
            stopSpeechToText()
        }
    }
    
    /// 音声認識を停止する
    func stopSpeechToText() {
        recognitionTask?.cancel()
        
        audioEngine.stop()
        
        inputNode?.removeTap(onBus: 0)
        try? audioSession?.setActive(false)
        audioSession = nil
        inputNode = nil
        
        isProcessing = false
        
        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil
    }
}

extension SpeechService: SFSpeechRecognizerDelegate {
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            print("✅ Available")
        } else {
            print("🔴 Unavailable")
            recognizedText = "Text recognition unavailable. Sorry!"
            stopSpeechToText()
        }
    }
}
