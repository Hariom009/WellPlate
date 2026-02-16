//
//  APIClientFactory.swift
//  WellPlate
//
//  Created by Claude on 16.02.2026.
//

import Foundation

/// Factory for providing the appropriate APIClient implementation
/// Returns MockAPIClient or real APIClient based on AppConfig.mockMode
///
/// IMPORTANT: This factory caches the client instance on first access.
/// Changing mockMode requires app restart for changes to take effect.
enum APIClientFactory {

    /// Cached singleton instance - evaluated once at first access
    /// This ensures consistent behavior throughout app lifecycle
    private static let _shared: APIClientProtocol = {
        let client: APIClientProtocol

        if AppConfig.shared.mockMode {
            #if DEBUG
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🎭 [APIClientFactory] Creating MockAPIClient")
            print("   Using offline mock data from bundle")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif
            client = MockAPIClient.shared
        } else {
            #if DEBUG
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🌐 [APIClientFactory] Creating Real APIClient")
            print("   Making actual network requests")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif
            client = APIClient.shared
        }

        return client
    }()

    /// Shared instance - returns cached singleton
    /// This is the main entry point for getting an API client
    static var shared: APIClientProtocol {
        _shared
    }

    // MARK: - Testing Support

    #if DEBUG
    /// Test instance - only available in DEBUG builds
    /// Used for dependency injection in unit tests
    private(set) static var _testInstance: APIClientProtocol?

    /// Set a custom instance for testing
    /// Only available in DEBUG builds
    /// - Parameter instance: Custom APIClient implementation or nil to reset
    static func setTestInstance(_ instance: APIClientProtocol?) {
        _testInstance = instance
        print("🧪 [APIClientFactory] Test instance set: \(instance != nil ? "Custom" : "Reset")")
    }

    /// Get testable instance - returns test instance if set, otherwise shared
    /// Only available in DEBUG builds
    static var testable: APIClientProtocol {
        _testInstance ?? _shared
    }
    #endif
}

// MARK: - Usage Examples

/*
 // In ViewModels or Services - use dependency injection:

 class UserViewModel: ObservableObject {
     private let apiClient: APIClientProtocol

     init(apiClient: APIClientProtocol = APIClientFactory.shared) {
         self.apiClient = apiClient
     }

     func fetchUser() async {
         do {
             let url = URL(string: "https://api.example.com/users/123")!
             let user = try await apiClient.get(url: url, headers: nil, responseType: User.self)
             // Handle user
         } catch {
             // Handle error
         }
     }
 }

 // In Tests - inject mock client:

 func testFetchUser() {
     let mockClient = MockAPIClient.shared
     let viewModel = UserViewModel(apiClient: mockClient)
     // Test with predictable mock data
 }

 // Toggle mock mode (requires app restart):

 #if DEBUG
 // Enable mock mode
 defaults write com.yourapp.WellPlate app.networking.mockMode -bool true

 // Disable mock mode
 defaults write com.yourapp.WellPlate app.networking.mockMode -bool false
 #endif
 */
