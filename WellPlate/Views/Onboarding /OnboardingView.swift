import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                // Page 1
                OnboardingPageView(
                    backgroundColor: Color(red: 0.85, green: 0.75, blue: 0.95),
                    illustration: "Good-Onboard",
                    title: "Your Smart Nutrition\nCompanion",
                    description: "Track your meals, monitor nutrients, and reach your health goals with AI-powered support.",
                    currentPage: $currentPage,
                    totalPages: 3,
                    isLastPage: false
                )
                .tag(0)
                
                // Page 2
                OnboardingPageView(
                    backgroundColor: Color(red: 0.45, green: 0.85, blue: 0.65),
                    illustration: "Groovy-Onboard",
                    title: "Track Everything That\nMatters",
                    description: "Log calories, macros, water, and activity — all in one place.",
                    currentPage: $currentPage,
                    totalPages: 3,
                    isLastPage: false
                )
                .tag(1)
                
                // Page 3
                OnboardingPageView(
                    backgroundColor: Color(red: 1.0, green: 0.55, blue: 0.35),
                    illustration: "Lemon-Onboard",
                    title: "Your Health Journey\nStarts Here",
                    description: "We help you choose healthier foods and enjoy tasty, nutritious meals for your well-being.",
                    currentPage: $currentPage,
                    totalPages: 3,
                    isLastPage: true
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
    }
}

// MARK: - Individual Page View

struct OnboardingPageView: View {
    let backgroundColor: Color
    let illustration: String
    let title: String
    let description: String
    @Binding var currentPage: Int
    let totalPages: Int
    let isLastPage: Bool
    
    var body: some View {
        ZStack {
            // Background color
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)
                
                // Illustration
                Image(illustration)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 350)
                    .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height: 60)
                
                // Title
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height: 16)
                
                // Description
                Text(description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.black : Color.black.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 30)
                
                // Liquid Glass Button
                BouncingArrowButton(
                    title: isLastPage ? "Get Started" : "Next",
                    action: {
                        if isLastPage {
                            // Navigate to main app
                            // You can add your navigation logic here
                        } else {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        }
                    }
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}


// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
