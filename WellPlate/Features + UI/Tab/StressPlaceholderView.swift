//
//  StressPlaceholderView.swift
//  WellPlate
//
//  Created by Hari's Mac on 21.02.2026.
//

import SwiftUI

/// Placeholder for the Stress screen.
struct StressPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.teal, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Stress")
                        .font(.r(.title2, .bold))

                    Text("Stress tracking & insights\ncoming soon.")
                        .font(.r(.subheadline, .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Stress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    StressPlaceholderView()
}
