import Foundation
import SwiftData

@Model
final class FoodLogEntry {
    var id: UUID
    var day: Date                // store startOfDay(date)
    var foodName: String
    var key: String              // normalized cache key
    var createdAt: Date

    // snapshot nutrition at log time (so old days don’t change if cache updates)
    var servingSize: String?
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var confidence: Double?

    init(day: Date,
         foodName: String,
         key: String,
         servingSize: String?,
         calories: Int,
         protein: Double,
         carbs: Double,
         fat: Double,
         fiber: Double,
         confidence: Double?,
         createdAt: Date = .now) {
        self.id = UUID()
        self.day = day
        self.foodName = foodName
        self.key = key
        self.servingSize = servingSize
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.confidence = confidence
        self.createdAt = createdAt
    }
}
