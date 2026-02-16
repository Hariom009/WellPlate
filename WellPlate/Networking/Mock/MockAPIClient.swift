//
//  MockAPIClient.swift
//  WellPlate
//
//  Created by Claude on 16.02.2026.
//

import Foundation

/// Mock implementation of APIClient for offline development and testing
/// Returns predefined JSON data from bundle instead of making network requests
class MockAPIClient: APIClientProtocol {
    static let shared = MockAPIClient()

    private init() {
        #if DEBUG
        print("🎭 [MockAPIClient] Initialized")
        #endif
    }

    // MARK: - Generic Request Method

    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        #if DEBUG
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎭 [MockAPIClient] \(method.rawValue) \(url.absoluteString)")
        if let headers = headers {
            print("   Headers: \(headers)")
        }
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            print("   Body: \(bodyString)")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif

        // Simulate network delay for realistic testing
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Get mock filename from registry
        guard let mockFileName = MockResponseRegistry.shared.mockFile(for: url, method: method) else {
            #if DEBUG
            print("⚠️ [MockAPIClient] No mock mapping found for \(url.path)")
            #endif
            throw APIError.noData
        }

        do {
            let result: T = try MockDataLoader.load(mockFileName)
            #if DEBUG
            print("✅ [MockAPIClient] Request completed successfully")
            #endif
            return result
        } catch {
            #if DEBUG
            print("❌ [MockAPIClient] Failed to load mock data: \(error.localizedDescription)")
            #endif
            throw APIError.noData
        }
    }

    func requestVoid(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws {
        #if DEBUG
        print("🎭 [MockAPIClient] \(method.rawValue) \(url.absoluteString) (void)")
        #endif

        // For void responses, just simulate delay and return
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        #if DEBUG
        print("✅ [MockAPIClient] Void request completed")
        #endif
    }

    // MARK: - Convenience Methods

    func get<T: Decodable>(
        url: URL,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        try await request(url: url, method: .get, headers: headers, responseType: responseType)
    }

    func post<T: Decodable>(
        url: URL,
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        try await request(url: url, method: .post, headers: headers, body: body, responseType: responseType)
    }

    func put<T: Decodable>(
        url: URL,
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        try await request(url: url, method: .put, headers: headers, body: body, responseType: responseType)
    }

    func delete<T: Decodable>(
        url: URL,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        try await request(url: url, method: .delete, headers: headers, responseType: responseType)
    }

    func patch<T: Decodable>(
        url: URL,
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        try await request(url: url, method: .patch, headers: headers, body: body, responseType: responseType)
    }

    // MARK: - Void Variants

    func deleteVoid(
        url: URL,
        headers: [String: String]? = nil
    ) async throws {
        try await requestVoid(url: url, method: .delete, headers: headers, body: nil)
    }

    func putVoid(
        url: URL,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws {
        try await requestVoid(url: url, method: .put, headers: headers, body: body)
    }

    // MARK: - Helper Methods

    func encodeBody<T: Encodable>(_ body: T) throws -> Data {
        try JSONEncoder().encode(body)
    }
}
