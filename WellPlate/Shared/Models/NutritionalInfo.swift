import Foundation

struct NutritionalInfo {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    
    init(calories: Int, protein: Double, carbs: Double, fat: Double, fiber: Double = 0) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
    }
}
