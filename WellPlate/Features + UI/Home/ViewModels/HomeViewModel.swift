import Foundation
import SwiftData
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var foodDescription: String = ""
    @Published var servingSize: String = ""
    @Published var nutritionalInfo: NutritionalInfo?
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    private let nutritionService: NutritionServiceProtocol
    private let modelContext: ModelContext

    init(modelContext: ModelContext,
         nutritionService: NutritionServiceProtocol = NutritionService()) {
        self.modelContext = modelContext
        self.nutritionService = nutritionService
    }

    func logFood(on date: Date) async {
        let trimmed = foodDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { showErrorMessage("Please enter a food description"); return }

        isLoading = true
        defer { isLoading = false }

        let day = Calendar.current.startOfDay(for: date)
        let key = normalizeFoodKey(trimmed)

        do {
            // 1) cache lookup
            if let cached = try fetchCache(key: key) {
                insertLog(from: cached, day: day, typedName: trimmed, key: key)
                nutritionalInfo = NutritionalInfo(
                    foodName: cached.displayName,
                    servingSize: cached.servingSize,
                    calories: cached.calories,
                    protein: cached.protein,
                    carbs: cached.carbs,
                    fat: cached.fat,
                    fiber: cached.fiber,
                    confidence: cached.confidence
                )
                try modelContext.save()
                return
            }

            // 2) API call
            let request = NutritionAnalysisRequest(
                foodDescription: trimmed,
                servingSize: servingSize.isEmpty ? nil : servingSize
            )
            let result = try await nutritionService.analyzeFood(request: request)
            nutritionalInfo = result

            // 3) upsert cache + insert log
            try upsertCache(from: result, key: key, displayName: trimmed)
            insertLog(from: result, day: day, typedName: trimmed, key: key)

            try modelContext.save()
        } catch {
            showErrorMessage("Failed to log food. Please try again.")
        }
    }

    private func fetchCache(key: String) throws -> FoodCache? {
        let fd = FetchDescriptor<FoodCache>(predicate: #Predicate { $0.key == key })
        return try modelContext.fetch(fd).first
    }

    private func upsertCache(from info: NutritionalInfo, key: String, displayName: String) throws {
        if let existing = try fetchCache(key: key) {
            existing.displayName = displayName
            existing.servingSize = info.servingSize
            existing.calories = info.calories
            existing.protein = info.protein
            existing.carbs = info.carbs
            existing.fat = info.fat
            existing.fiber = info.fiber
            existing.confidence = info.confidence
            existing.updatedAt = .now
        } else {
            let cache = FoodCache(
                key: key,
                displayName: displayName,
                servingSize: info.servingSize,
                calories: info.calories,
                protein: info.protein,
                carbs: info.carbs,
                fat: info.fat,
                fiber: info.fiber,
                confidence: info.confidence
            )
            modelContext.insert(cache)
        }
    }

    private func insertLog(from cache: FoodCache, day: Date, typedName: String, key: String) {
        let entry = FoodLogEntry(
            day: day,
            foodName: typedName,
            key: key,
            servingSize: cache.servingSize,
            calories: cache.calories,
            protein: cache.protein,
            carbs: cache.carbs,
            fat: cache.fat,
            fiber: cache.fiber,
            confidence: cache.confidence
        )
        modelContext.insert(entry)
    }

    private func insertLog(from info: NutritionalInfo, day: Date, typedName: String, key: String) {
        let entry = FoodLogEntry(
            day: day,
            foodName: typedName,
            key: key,
            servingSize: info.servingSize,
            calories: info.calories,
            protein: info.protein,
            carbs: info.carbs,
            fat: info.fat,
            fiber: info.fiber,
            confidence: info.confidence
        )
        modelContext.insert(entry)
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
