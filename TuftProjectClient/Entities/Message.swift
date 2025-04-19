//
//  AuthToken.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/12.
//

import Foundation

struct ResponseWrapper: Codable {
    let response: MessageResponse
}

struct MessageResponse: Codable {
    let messages: [Message]
}

struct Message: Codable, Sendable {
    var type: String
    var content: String
    var emotion: String?
}

