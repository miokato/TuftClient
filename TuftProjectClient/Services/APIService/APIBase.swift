//
//  APIBase.swift
//  TuftProjectClient
//
//  Created by mio kato on 2025/04/12.
//

import Foundation

public enum APIBaseError: Error {
    case urlDoesNotExist
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

public class APIInputBase {
    public let url: String
    public let httpMethod: HTTPMethod
    public let isUpload: Bool
    public var headers: [String: String]?
    public let queries: [String: String]?
    public let parameters: [String: Any]?
    public let fileUrls: [String: URL?]?
    
    public init(
        url: String,
        httpMethod: HTTPMethod,
        isUpload: Bool,
        headers: [String: String]?=nil,
        queries: [String : String]?=nil,
        parameters: [String: Any]?=nil,
        fileUrls: [String: URL?]?=nil
    ) {
        self.url = url
        self.httpMethod = httpMethod
        self.isUpload = isUpload
        self.headers = headers
        self.queries = queries
        self.parameters = parameters
        self.fileUrls = fileUrls
    }
}

protocol APIBase {
    func request(_ input: APIInputBase) async throws -> (Data, URLResponse)
}

extension APIBase {
    public func request(_ input: APIInputBase) async throws -> (Data, URLResponse) {
        guard var urlComponents = URLComponents(string: input.url) else {
            throw APIBaseError.urlDoesNotExist
        }
        
        urlComponents.queryItems = input.queries?.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = urlComponents.url else {
            throw APIBaseError.urlDoesNotExist
        }
        
        var request = URLRequest(url: url)
        
        if let headers = input.headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        request.httpMethod = input.httpMethod.rawValue
        
        if let parameters = input.parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        }
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        return try await URLSession.shared.data(for: request)
    }
}
