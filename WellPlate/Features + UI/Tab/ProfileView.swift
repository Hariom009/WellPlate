//
//  ProfileView.swift
//  WellPlate
//
//  Created by Hari's Mac on 20.02.2026.
//

import SwiftUI

/// Placeholder for the Profile screen.
struct ProfilePlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.orange.opacity(0.8))

                    Text("Profile")
                        .font(.r(.title2, .bold))

                    Text("Goals, preferences & settings\ncoming soon.")
                        .font(.r(.subheadline, .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ProfilePlaceholderView()
}
