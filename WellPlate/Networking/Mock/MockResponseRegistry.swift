//
//  MockResponseRegistry.swift
//  WellPlate
//
//  Created by Claude on 16.02.2026.
//

import Foundation

/// Registry for mapping URL patterns to mock data files
/// Handles complex URLs with path parameters, query strings, etc.
class MockResponseRegistry {
    static let shared = MockResponseRegistry()

    private var registry: [URLPattern: String] = [:]

    private init() {
        setupDefaultMappings()
    }

    // MARK: - URL Pattern

    struct URLPattern: Hashable {
        let path: String
        let method: HTTPMethod

        init(_ path: String, method: HTTPMethod) {
            self.path = path
            self.method = method
        }
    }

    // MARK: - Registration

    /// Register a mock file for a URL pattern
    /// - Parameters:
    ///   - path: URL path (can include {id} for path parameters)
    ///   - method: HTTP method
    ///   - mockFile: Mock filename (without .json extension)
    func register(path: String, method: HTTPMethod, mockFile: String) {
        let pattern = URLPattern(path, method: method)
        registry[pattern] = mockFile

        #if DEBUG
        print("📝 [MockRegistry] Registered: \(method.rawValue) \(path) → \(mockFile).json")
        #endif
    }

    /// Get mock filename for URL and method
    /// - Parameters:
    ///   - url: The request URL
    ///   - method: HTTP method
    /// - Returns: Mock filename (without .json) or nil if no mapping found
    func mockFile(for url: URL, method: HTTPMethod) -> String? {
        // Try exact path match first
        let exactPattern = URLPattern(url.path, method: method)
        if let mockFile = registry[exactPattern] {
            #if DEBUG
            print("✅ [MockRegistry] Exact match: \(method.rawValue) \(url.path) → \(mockFile).json")
            #endif
            return mockFile
        }

        // Try pattern matching (e.g., /api/users/{id})
        for (pattern, mockFile) in registry {
            if matchesPattern(pattern.path, actualPath: url.path) && pattern.method == method {
                #if DEBUG
                print("✅ [MockRegistry] Pattern match: \(pattern.path) matched \(url.path) → \(mockFile).json")
                #endif
                return mockFile
            }
        }

        // Fallback: generate filename from path
        #if DEBUG
        print("⚠️  [MockRegistry] No mapping found, using fallback for: \(method.rawValue) \(url.path)")
        #endif
        return generateDefaultFilename(for: url, method: method)
    }

    // MARK: - Pattern Matching

    /// Check if a URL path matches a pattern
    /// Supports {id}, {userId}, etc. as wildcards
    private func matchesPattern(_ pattern: String, actualPath: String) -> Bool {
        // Convert pattern like /api/users/{id} to regex
        var regexPattern = NSRegularExpression.escapedPattern(for: pattern)

        // Replace {id}, {userId}, etc. with regex to match any value
        regexPattern = regexPattern.replacingOccurrences(
            of: "\\\\\\{[^}]+\\\\\\}",
            with: "[^/]+",
            options: .regularExpression
        )

        guard let regex = try? NSRegularExpression(pattern: "^" + regexPattern + "$") else {
            return false
        }

        let range = NSRange(actualPath.startIndex..., in: actualPath)
        return regex.firstMatch(in: actualPath, range: range) != nil
    }

    /// Generate a default filename from URL
    /// Sanitizes path to create a valid filename
    private func generateDefaultFilename(for url: URL, method: HTTPMethod) -> String {
        // Sanitize path for filename
        let sanitized = url.path
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        return "mock\(sanitized)_\(method.rawValue.lowercased())"
    }

    // MARK: - Default Mappings

    /// Setup default URL → mock file mappings
    /// Add your API endpoint mappings here
    private func setupDefaultMappings() {
        #if DEBUG
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📋 [MockRegistry] Setting up default mappings")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif

        // Example mappings - customize for your API
        register(path: "/api/health", method: .get, mockFile: "mock_health_check")
        register(path: "/api/users", method: .get, mockFile: "mock_users_list")
        register(path: "/api/users/{id}", method: .get, mockFile: "mock_user_detail")
        register(path: "/api/users/{id}", method: .delete, mockFile: "mock_user_delete")
        register(path: "/api/users", method: .post, mockFile: "mock_user_create")

        // Add your API endpoint mappings below:
        register(path: "/api/nutrition/analyze", method: .post, mockFile: "mock_nutrition_biryani")

        #if DEBUG
        print("✅ [MockRegistry] \(registry.count) mappings registered")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif
    }
}
