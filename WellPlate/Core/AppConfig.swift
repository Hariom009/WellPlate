//
//  AppConfig.swift
//  WellPlate
//
//  Created by Claude on 16.02.2026.
//

import Foundation

/// Application-wide configuration manager
class AppConfig {
    static let shared = AppConfig()

    private init() {
        // Initialize with default settings
    }

    /// Controls whether to use mock API client or real API client
    /// - In DEBUG: Configurable via UserDefaults, defaults to true for development convenience
    /// - In RELEASE: Always false (forced for production safety)
    /// - Note: Changing this requires app restart due to factory caching
    var mockMode: Bool {
        get {
            #if DEBUG
            // Check if value has been explicitly set
            guard UserDefaults.standard.object(forKey: "app.networking.mockMode") != nil else {
                return true  // Development-friendly default
            }
            return UserDefaults.standard.bool(forKey: "app.networking.mockMode")
            #else
            return false  // Always false in production
            #endif
        }
        set {
            #if DEBUG
            UserDefaults.standard.set(newValue, forKey: "app.networking.mockMode")
            print("🔧 [AppConfig] Mock Mode changed to: \(newValue)")
            print("⚠️  App restart required for changes to take effect")
            #endif
        }
    }

    /// Log the current configuration mode
    func logCurrentMode() {
        #if DEBUG
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔧 [AppConfig] Mock Mode: \(mockMode ? "ENABLED ✅" : "DISABLED ❌")")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif
    }
}
