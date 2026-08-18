//
//  SplashView.swift
//  wave Watch App
//
//  watchOS swaps its own launch image out the moment the first view is built,
//  which on a cream app means a flash of half-drawn Home. This covers that gap
//  with the app mark on the same cream fade every other screen sits on, so the
//  app appears to open into itself rather than snap into place.
//
//  It is a cover, not a page: it plays once, holds for a beat, and lifts. Home's
//  entrance animation waits for it (see Entrance.swift), so the two read as one
//  opening rather than two things happening at once.
//

import SwiftUI

struct SplashView: View {
    /// How long the mark is held before the splash lifts. Long enough to read
    /// as intentional, short enough that it never becomes a wait.
    static let hold: Double = 1.1
    static let fadeOut: Double = 0.35

    /// Whole duration, which is what the rest of the app schedules against.
    static var duration: Double { hold + fadeOut }

    /// Drives the mark's entrance; starts small and transparent, unlike every
    /// other primitive in the app, because here there is nothing to preserve.
    @State private var t: Double = 0

    var body: some View {
        ZStack {
            ScreenFade()

            VStack(spacing: 10) {
                Image("SplashIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Metrics.splashIcon, height: Metrics.splashIcon)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.splashIcon * 0.24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Metrics.splashIcon * 0.24, style: .continuous)
                            .stroke(Palette.border, lineWidth: 1)
                    )
                    .scaleEffect(0.72 + 0.28 * t)
                    .opacity(min(t * 2, 1))

                Text("wave")
                    .font(WaveFont.heading(19))
                    .foregroundStyle(Palette.orange)
                    // Trails the mark, so the name settles after it.
                    .opacity(max(t * 1.6 - 0.6, 0))
            }
        }
        .task {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { t = 1 }
        }
    }
}

#Preview {
    SplashView()
}
