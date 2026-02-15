import SwiftUI
import Vision
import UIKit

struct FoodScannerView: View {
    @StateObject private var viewModel = FoodScannerViewModel()
    @State private var showCamera = false
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    if viewModel.capturedImage == nil {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Food Nutrition Scanner")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Take a photo of your food to get nutritional information")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        
                        Spacer()
                    }
                    
                    // Captured Image Display
                    if let image = viewModel.capturedImage {
                        VStack(spacing: 16) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                                .padding(.horizontal)
                            
                            if viewModel.isAnalyzing {
                                HStack(spacing: 12) {
                                    ProgressView()
                                    Text("Analyzing food...")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                    }
                    
                    // Classification Results
                    if let classification = viewModel.foodClassification {
                        ClassificationResultView(classification: classification)
                    }
                    
                    // Nutritional Information
                    if let nutrition = viewModel.nutritionalInfo {
                        NutritionalInfoView(nutrition: nutrition)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text(viewModel.capturedImage == nil ? "Take Photo" : "Retake Photo")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.capturedImage != nil {
                            Button(action: {
                                viewModel.reset()
                            }) {
                                Text("Clear")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Food Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCamera) {
                ImagePicker(
                    sourceType: .camera,
                    selectedImage: $viewModel.capturedImage,
                    onImageSelected: {
                        viewModel.analyzeFood()
                    }
                )
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Classification Result View
struct ClassificationResultView: View {
    let classification: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Identified Food")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text(classification.capitalized)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Nutritional Info View
struct NutritionalInfoView: View {
    let nutrition: NutritionalInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Nutritional Information")
                    .font(.headline)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                NutrientRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    label: "Calories",
                    value: "\(nutrition.calories)",
                    unit: "kcal"
                )
                
                NutrientRow(
                    icon: "drop.fill",
                    iconColor: .yellow,
                    label: "Fat",
                    value: String(format: "%.1f", nutrition.fat),
                    unit: "g"
                )
                
                NutrientRow(
                    icon: "bolt.fill",
                    iconColor: .red,
                    label: "Protein",
                    value: String(format: "%.1f", nutrition.protein),
                    unit: "g"
                )
                
                NutrientRow(
                    icon: "leaf.fill",
                    iconColor: .green,
                    label: "Carbs",
                    value: String(format: "%.1f", nutrition.carbs),
                    unit: "g"
                )
                
                if nutrition.fiber > 0 {
                    NutrientRow(
                        icon: "arrow.down.circle.fill",
                        iconColor: .brown,
                        label: "Fiber",
                        value: String(format: "%.1f", nutrition.fiber),
                        unit: "g"
                    )
                }
            }
            
            Text("Per 100g serving")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .padding(.horizontal)
    }
}

// MARK: - Nutrient Row
struct NutrientRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .fontWeight(.semibold)
                Text(unit)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
    }
}

#Preview {
    FoodScannerView()
}
