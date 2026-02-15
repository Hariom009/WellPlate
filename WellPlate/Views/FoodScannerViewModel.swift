import SwiftUI
import Vision
import Combine

class FoodScannerViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var foodClassification: String?
    @Published var nutritionalInfo: NutritionalInfo?
    @Published var isAnalyzing = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    func analyzeFood() {
        guard let image = capturedImage else {
            showErrorAlert("No image to analyze")
            return
        }
        
        isAnalyzing = true
        
        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: image) else {
            showErrorAlert("Failed to process image")
            isAnalyzing = false
            return
        }
        
        // Create Vision request
        let request = VNClassifyImageRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.handleClassificationResults(request: request, error: error)
            }
        }
        
        // Perform the request
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.showErrorAlert("Failed to analyze image: \(error.localizedDescription)")
                    self?.isAnalyzing = false
                }
            }
        }
    }
    
    func reset() {
        capturedImage = nil
        foodClassification = nil
        nutritionalInfo = nil
        isAnalyzing = false
    }
    
    // MARK: - Private Methods
    
    private func handleClassificationResults(request: VNRequest, error: Error?) {
        isAnalyzing = false
        
        if let error = error {
            showErrorAlert("Classification failed: \(error.localizedDescription)")
            return
        }
        
        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else {
            showErrorAlert("No classification results found")
            return
        }
        
        // Filter for food-related classifications with decent confidence
        let foodResults = results.filter { observation in
            observation.confidence > 0.3 && isFoodRelated(observation.identifier)
        }
        
        guard let bestFoodResult = foodResults.first else {
            // If no food detected, show the top result anyway
            foodClassification = cleanIdentifier(topResult.identifier)
            nutritionalInfo = getNutritionalInfo(for: topResult.identifier)
            return
        }
        
        // Use the best food-related result
        foodClassification = cleanIdentifier(bestFoodResult.identifier)
        nutritionalInfo = getNutritionalInfo(for: bestFoodResult.identifier)
        
        print("Top classifications:")
        results.prefix(5).forEach { observation in
            print("  - \(observation.identifier): \(observation.confidence * 100)%")
        }
    }
    
    private func isFoodRelated(_ identifier: String) -> Bool {
        let foodKeywords = [
            "food", "fruit", "vegetable", "meat", "bread", "pasta", "rice",
            "pizza", "burger", "sandwich", "salad", "soup", "dessert", "cake",
            "cookie", "apple", "banana", "orange", "chicken", "beef", "fish",
            "cheese", "egg", "milk", "coffee", "tea", "drink", "beverage",
            "restaurant", "meal", "breakfast", "lunch", "dinner", "snack"
        ]
        
        let lowerIdentifier = identifier.lowercased()
        return foodKeywords.contains { lowerIdentifier.contains($0) }
    }
    
    private func cleanIdentifier(_ identifier: String) -> String {
        // Remove common prefixes and clean up the identifier
        var cleaned = identifier
        
        // Remove common vision classification prefixes
        if let commaIndex = cleaned.firstIndex(of: ",") {
            cleaned = String(cleaned[..<commaIndex])
        }
        
        // Replace underscores and hyphens with spaces
        cleaned = cleaned.replacingOccurrences(of: "_", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "-", with: " ")
        
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
    
    private func getNutritionalInfo(for identifier: String) -> NutritionalInfo {
        let lowerIdentifier = identifier.lowercased()
        
        // Comprehensive nutritional database (per 100g)
        // This is a simplified version - in production, you'd use a real API
        
        // Fruits
        if lowerIdentifier.contains("apple") {
            return NutritionalInfo(calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4)
        } else if lowerIdentifier.contains("banana") {
            return NutritionalInfo(calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6)
        } else if lowerIdentifier.contains("orange") {
            return NutritionalInfo(calories: 47, protein: 0.9, carbs: 12, fat: 0.1, fiber: 2.4)
        } else if lowerIdentifier.contains("strawberry") || lowerIdentifier.contains("strawberries") {
            return NutritionalInfo(calories: 32, protein: 0.7, carbs: 8, fat: 0.3, fiber: 2.0)
        } else if lowerIdentifier.contains("grape") {
            return NutritionalInfo(calories: 69, protein: 0.7, carbs: 18, fat: 0.2, fiber: 0.9)
        } else if lowerIdentifier.contains("watermelon") {
            return NutritionalInfo(calories: 30, protein: 0.6, carbs: 8, fat: 0.2, fiber: 0.4)
        }
        
        // Vegetables
        else if lowerIdentifier.contains("broccoli") {
            return NutritionalInfo(calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6)
        } else if lowerIdentifier.contains("carrot") {
            return NutritionalInfo(calories: 41, protein: 0.9, carbs: 10, fat: 0.2, fiber: 2.8)
        } else if lowerIdentifier.contains("tomato") {
            return NutritionalInfo(calories: 18, protein: 0.9, carbs: 4, fat: 0.2, fiber: 1.2)
        } else if lowerIdentifier.contains("spinach") {
            return NutritionalInfo(calories: 23, protein: 2.9, carbs: 4, fat: 0.4, fiber: 2.2)
        } else if lowerIdentifier.contains("potato") {
            return NutritionalInfo(calories: 77, protein: 2.0, carbs: 17, fat: 0.1, fiber: 2.1)
        }
        
        // Proteins
        else if lowerIdentifier.contains("chicken") {
            return NutritionalInfo(calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0)
        } else if lowerIdentifier.contains("beef") {
            return NutritionalInfo(calories: 250, protein: 26, carbs: 0, fat: 15, fiber: 0)
        } else if lowerIdentifier.contains("fish") || lowerIdentifier.contains("salmon") {
            return NutritionalInfo(calories: 208, protein: 20, carbs: 0, fat: 13, fiber: 0)
        } else if lowerIdentifier.contains("egg") {
            return NutritionalInfo(calories: 155, protein: 13, carbs: 1.1, fat: 11, fiber: 0)
        }
        
        // Grains & Carbs
        else if lowerIdentifier.contains("rice") {
            return NutritionalInfo(calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4)
        } else if lowerIdentifier.contains("bread") {
            return NutritionalInfo(calories: 265, protein: 9, carbs: 49, fat: 3.2, fiber: 2.7)
        } else if lowerIdentifier.contains("pasta") {
            return NutritionalInfo(calories: 131, protein: 5, carbs: 25, fat: 1.1, fiber: 1.8)
        } else if lowerIdentifier.contains("oat") {
            return NutritionalInfo(calories: 389, protein: 17, carbs: 66, fat: 7, fiber: 10.6)
        }
        
        // Fast Food
        else if lowerIdentifier.contains("pizza") {
            return NutritionalInfo(calories: 266, protein: 11, carbs: 33, fat: 10, fiber: 2.5)
        } else if lowerIdentifier.contains("burger") || lowerIdentifier.contains("hamburger") {
            return NutritionalInfo(calories: 295, protein: 17, carbs: 24, fat: 14, fiber: 1.5)
        } else if lowerIdentifier.contains("sandwich") {
            return NutritionalInfo(calories: 250, protein: 12, carbs: 30, fat: 8, fiber: 2.0)
        } else if lowerIdentifier.contains("fries") || lowerIdentifier.contains("french fries") {
            return NutritionalInfo(calories: 312, protein: 3.4, carbs: 41, fat: 15, fiber: 3.8)
        }
        
        // Desserts
        else if lowerIdentifier.contains("cake") {
            return NutritionalInfo(calories: 257, protein: 2.6, carbs: 42, fat: 9, fiber: 0.6)
        } else if lowerIdentifier.contains("cookie") {
            return NutritionalInfo(calories: 502, protein: 5.9, carbs: 64, fat: 25, fiber: 2.0)
        } else if lowerIdentifier.contains("ice cream") {
            return NutritionalInfo(calories: 207, protein: 3.5, carbs: 24, fat: 11, fiber: 0.7)
        } else if lowerIdentifier.contains("chocolate") {
            return NutritionalInfo(calories: 546, protein: 4.9, carbs: 61, fat: 31, fiber: 7.0)
        }
        
        // Dairy
        else if lowerIdentifier.contains("milk") {
            return NutritionalInfo(calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3, fiber: 0)
        } else if lowerIdentifier.contains("cheese") {
            return NutritionalInfo(calories: 402, protein: 25, carbs: 1.3, fat: 33, fiber: 0)
        } else if lowerIdentifier.contains("yogurt") {
            return NutritionalInfo(calories: 59, protein: 10, carbs: 3.6, fat: 0.4, fiber: 0)
        }
        
        // Beverages
        else if lowerIdentifier.contains("coffee") {
            return NutritionalInfo(calories: 2, protein: 0.3, carbs: 0, fat: 0, fiber: 0)
        } else if lowerIdentifier.contains("tea") {
            return NutritionalInfo(calories: 1, protein: 0, carbs: 0.3, fat: 0, fiber: 0)
        } else if lowerIdentifier.contains("juice") {
            return NutritionalInfo(calories: 45, protein: 0.5, carbs: 11, fat: 0.2, fiber: 0.2)
        }
        
        // Nuts & Seeds
        else if lowerIdentifier.contains("almond") {
            return NutritionalInfo(calories: 579, protein: 21, carbs: 22, fat: 50, fiber: 12.5)
        } else if lowerIdentifier.contains("peanut") {
            return NutritionalInfo(calories: 567, protein: 26, carbs: 16, fat: 49, fiber: 8.5)
        }
        
        // Salads
        else if lowerIdentifier.contains("salad") {
            return NutritionalInfo(calories: 33, protein: 2.5, carbs: 6, fat: 0.3, fiber: 2.1)
        }
        
        // Default generic food
        else {
            return NutritionalInfo(calories: 150, protein: 8, carbs: 20, fat: 5, fiber: 2.0)
        }
    }
    
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }
}
