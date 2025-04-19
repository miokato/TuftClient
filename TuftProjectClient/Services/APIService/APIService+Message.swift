//
//  APIService+User.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/12.
//

import Foundation

/// /api/thread
extension APIService {
    final class ThreadInput: APIInputBase {
        init(url: String) {
            super.init(
                url: url,
                httpMethod: .post,
                isUpload: false,
                headers: APIService.httpHeaders(),
                parameters: [
                    "metadata": [
                        "purpose": "conversation"
                    ]
                ]
            )
        }
    }
    
    func createThread() async throws -> ThreadResponse {
        let url = Domain.host + Path.thread
        let input = ThreadInput(url: url)
        let (data, _) = try await request(input)
        return try JSONDecoder().decode(ThreadResponse.self, from: data)
    }
}

/// /api/threads/<id>/runs/wait
extension APIService {
    final class MessageInput: APIInputBase {
        init(url: String, message: String) {
            super.init(
                url: url,
                httpMethod: .post,
                isUpload: false,
                headers: APIService.httpHeaders(),
                parameters: [
                    "assistant_id": "agent",
                    "input": [
                        "messages": [
                            ["role": "human", "content": message]
                        ]
                    ],
                    "config": [
                        "configurable": [
                            "response_model_extras": [
                                "timestamp": "auto",
                                "version": "1.0"
                            ]
                        ]
                    ]
                ]
            )
        }
    }
    
    func sendMessage(id: String, message: String) async throws -> Message? {
        let url = Domain.host + String(format: Path.message, "\(id)")
        let input = MessageInput(url: url, message: message)
        let (data, res) = try await request(input)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Failed to parse JSON response")
            return nil
        }
        
        // エラーチェック
        if let errorDict = json["__error__"] as? [String: Any],
           let errorMessage = errorDict["message"] as? String {
            print("Server error: \(errorMessage)")
            return nil
        }
        
        // レスポンスの解析（実際のレスポンス構造に合わせて修正）
        let messagesArray: [[String: Any]]?
        
        // レスポンス構造の可能性をチェック
        if let outputMessages = json["output"] as? [String: Any],
           let msgs = outputMessages["messages"] as? [[String: Any]] {
            // output.messages 構造の場合
            messagesArray = msgs
        } else if let msgs = json["messages"] as? [[String: Any]] {
            // フラットなmessages構造の場合
            messagesArray = msgs
        } else {
            print("Could not find messages array in response")
            return nil
        }
        
        // 最後のメッセージ（AIからの応答）を取得
        guard let responseMessages = messagesArray,
              let lastAiMessage = responseMessages.last(where: { ($0["type"] as? String) == "ai" }) else {
            print("No AI message found in response")
            return nil
        }
        
        // メッセージの内容を取得
        let content = lastAiMessage["content"] as? String ?? ""
        
        // メタデータを取得
        var metadata: [String: Any]? = nil
        var emotion: String? = nil
        
        // additional_kwargsからjson_dataを取得
        if let additionalKwargs = lastAiMessage["additional_kwargs"] as? [String: Any],
           let jsonData = additionalKwargs["json_data"] as? [String: Any] {
            metadata = jsonData
            emotion = jsonData["emotion"] as? String
        }
        
        // レガシー形式のサポート（後方互換性）
        if emotion == nil && content.contains("```json") {
            if let jsonString = content.components(separatedBy: "```json")
                .last?
                .components(separatedBy: "```")
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               let jsonData = jsonString.data(using: .utf8),
               let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                
                emotion = jsonDict["emotion"] as? String
                if metadata == nil {
                    metadata = jsonDict
                }
            }
        }
        
        print("Parsed content: \(content)")
        print("Parsed emotion: \(emotion ?? "none")")
        print("Parsed metadata: \(metadata ?? [:])")
        return Message(type: "ai", content: content, emotion: emotion)
    }
}
