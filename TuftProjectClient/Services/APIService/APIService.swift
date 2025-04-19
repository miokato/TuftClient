//
//  APIService.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/12.
//

import Foundation

struct APIService: APIBase {
    static let shared = APIService()
}


extension APIService {
    static func httpHeaders() -> [String: String] {
        var headers = [String: String]()

        return headers
    }
}

