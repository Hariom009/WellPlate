//
//  SleepView.swift
//  WellPlate
//
//  Created by Hari's Mac on 20.02.2026.
//

import SwiftUI

/// Placeholder for the Sleep screen.
/// Replace with the real HealthKit-powered view in Phase 4.
struct SleepPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Sleep")
                        .font(.r(.title2, .bold))

                    Text("Sleep analysis & trends\ncoming soon.")
                        .font(.r(.subheadline, .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SleepPlaceholderView()
}
