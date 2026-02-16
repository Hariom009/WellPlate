//
//  NutritionService.swift
//  WellPlate
//
//  Created by Claude on 16.02.2026.
//

import Foundation

/// Implementation of NutritionServiceProtocol using APIClient
class NutritionService: NutritionServiceProtocol {
    private let apiClient: APIClientProtocol

    /// Initialize with dependency injection
    /// - Parameter apiClient: The API client to use (defaults to shared instance)
    init(apiClient: APIClientProtocol = APIClientFactory.shared) {
        self.apiClient = apiClient
    }

    /// Analyze food and return nutritional information
    func analyzeFood(request: NutritionAnalysisRequest) async throws -> NutritionalInfo {
        // Prepare URL
        let endpoint = "/api/nutrition/analyze"
        guard let url = URL(string: "https://api.wellplate.com\(endpoint)") else {
            throw APIError.invalidURL
        }

        #if DEBUG
        print("🔍 [NutritionService] Analyzing food: \(request.foodDescription)")
        #endif

        // Encode request body
        let bodyData = try apiClient.encodeBody(request)

        // Make API request
        let response: NutritionAnalysisResponse = try await apiClient.request(
            url: url,
            method: .post,
            headers: nil,
            body: bodyData,
            responseType: NutritionAnalysisResponse.self
        )

        // Check response success
        guard response.success else {
            #if DEBUG
            print("❌ [NutritionService] API returned success=false: \(response.message)")
            #endif
            throw APIError.serverError(statusCode: 400, message: response.message)
        }

        // Convert to domain model
        let nutritionalInfo = response.toNutritionalInfo()

        #if DEBUG
        print("✅ [NutritionService] Analysis complete: \(nutritionalInfo.foodName)")
        #endif

        return nutritionalInfo
    }
}
