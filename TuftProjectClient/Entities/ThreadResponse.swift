//
//  ThreadResponse.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/13.
//
import Foundation

struct ThreadResponse: Codable {
    let id: String
    
    enum CodingKeys: String, CodingKey {
        case id = "thread_id"
    }
}
