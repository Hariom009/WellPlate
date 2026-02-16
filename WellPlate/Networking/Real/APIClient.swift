//
//  APIClient.swift
//  WellPlate
//
//  Updated by Claude on 16.02.2026.
//

import Foundation

class APIClient: APIClientProtocol {
    static let shared = APIClient()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Generic Request Method

    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8)
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return decodedResponse
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func requestVoid(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws {
        // For void responses, we make the request but don't decode a response
        let _: EmptyResponse = try await request(
            url: url,
            method: method,
            headers: headers,
            body: body,
            responseType: EmptyResponse.self
        )
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
