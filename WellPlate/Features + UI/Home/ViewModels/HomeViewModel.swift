//
//  HomeViewModel.swift
//  WellPlate
//
//  Created by Claude on 16.02.2026.
//

import Foundation
import Combine

/// ViewModel for HomeView
/// Handles business logic for food nutrition analysis
@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    /// User input: food description
    @Published var foodDescription: String = ""

    /// User input: serving size (optional)
    @Published var servingSize: String = ""

    /// Analysis result
    @Published var nutritionalInfo: NutritionalInfo?

    /// Loading state
    @Published var isLoading: Bool = false

    /// Error state
    @Published var showError: Bool = false

    /// Error message
    @Published var errorMessage: String = ""

    // MARK: - Dependencies

    private let nutritionService: NutritionServiceProtocol

    // MARK: - Computed Properties

    /// Whether the analyze button should be enabled
    var isAnalyzeButtonEnabled: Bool {
        !foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    // MARK: - Initialization

    /// Initialize with dependency injection
    /// - Parameter nutritionService: The nutrition service to use
    init(nutritionService: NutritionServiceProtocol = NutritionService()) {
        self.nutritionService = nutritionService
    }

    // MARK: - Actions

    /// Analyze the entered food
    func analyzeFood() async {
        // Validate input
        let trimmedDescription = foodDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else {
            showErrorMessage("Please enter a food description")
            return
        }

        // Start loading
        isLoading = true
        errorMessage = ""
        showError = false

        do {
            // Create request
            let request = NutritionAnalysisRequest(
                foodDescription: trimmedDescription,
                servingSize: servingSize.isEmpty ? nil : servingSize
            )

            // Call service
            let result = try await nutritionService.analyzeFood(request: request)

            // Update UI on success
            nutritionalInfo = result
            isLoading = false

            #if DEBUG
            print("✅ [HomeViewModel] Successfully analyzed: \(result.foodName)")
            #endif

        } catch let error as APIError {
            // Handle API errors
            handleError(error)
        } catch {
            // Handle unexpected errors
            showErrorMessage("An unexpected error occurred. Please try again.")
            #if DEBUG
            print("❌ [HomeViewModel] Unexpected error: \(error)")
            #endif
        }
    }

    /// Clear results and reset form
    func clearResults() {
        nutritionalInfo = nil
        foodDescription = ""
        servingSize = ""
        errorMessage = ""
        showError = false
    }

    // MARK: - Error Handling

    private func handleError(_ error: APIError) {
        isLoading = false

        let message: String
        switch error {
        case .networkError(let underlyingError):
            message = "Network error. Please check your connection."
            #if DEBUG
            print("❌ [HomeViewModel] Network error: \(underlyingError)")
            #endif
        case .invalidURL:
            message = "Invalid request. Please try again."
        case .invalidResponse:
            message = "Invalid response from server. Please try again."
        case .noData:
            message = "No data received. Please try again."
        case .decodingError(let underlyingError):
            message = "Failed to process response. Please try again."
            #if DEBUG
            print("❌ [HomeViewModel] Decoding error: \(underlyingError)")
            #endif
        case .serverError(let statusCode, let msg):
            message = msg ?? "Server error (\(statusCode)). Please try again."
        }

        showErrorMessage(message)
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        isLoading = false

        #if DEBUG
        print("⚠️  [HomeViewModel] Error: \(message)")
        #endif
    }
}
