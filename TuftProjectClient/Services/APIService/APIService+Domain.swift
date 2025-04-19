//
//  APIService+Domain.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/12.
//

import Foundation

extension APIService {
    enum Domain {
        static let host = Constants.ngrokDomain
    }

    enum Path {
        static let thread = "/threads"
        static let message = "/threads/%@/runs/wait"
    }
}
