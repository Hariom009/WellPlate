//
//  RootView.swift
//  WellPlate
//
//  Created by Hari's Mac on 16.02.2026.
//  Updated by Claude on 16.02.2026.
//

import SwiftUI

struct RootView: View {
    @State private var showSplash = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .onAppear {
                        // Transition to HomeView after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                HomeView(viewModel: HomeViewModel(modelContext: modelContext))
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    RootView()
}
