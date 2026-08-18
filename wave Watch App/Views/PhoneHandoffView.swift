//
//  PhoneHandoffView.swift
//  wave Watch App
//
//  Only one thing on the watch hands off now: Bubble Release. Every other
//  exercise is something you do away from a screen, so the watch is the better
//  place for it — a game needs a phone.
//

import SwiftUI

struct PhoneHandoffView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                OtterAnimationView(clip: .calm, size: Metrics.otterSize)
                    .overlay(Circle().stroke(Palette.card, lineWidth: 2))

                Text("Bubble Release is on your phone")
                    .font(WaveFont.title)
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Open Wave to play it.")
                    .font(WaveFont.body)
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    Image(systemName: "iphone")
                        .font(.system(size: 16))
                    Text("Wave")
                        .font(WaveFont.headline)
                }
                .foregroundStyle(Palette.orange)
                .waveCard(padding: 10)

                PillButton(title: "Got it", style: .ink) { dismiss() }
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.bottom, 10)
        }
        .waveScreen()
    }
}

#Preview {
    PhoneHandoffView()
}
