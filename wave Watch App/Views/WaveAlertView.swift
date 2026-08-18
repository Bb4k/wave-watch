//
//  WaveAlertView.swift
//  wave Watch App
//
//  What the watch shows when Wave thinks a craving is coming. Supportive, not
//  alarming — the whole point is a small pause between the craving and the
//  response, so the copy never blames and the wave itself is neutral.
//
//  It lives as the second page so it can be demoed by swiping, but this is the
//  screen a notification would open.
//

import SwiftUI

struct WaveAlertView: View {
    @EnvironmentObject private var store: WaveStore

    @State private var replay = 0

    private var level: WaveLevel { store.waveLevel }

    var body: some View {
        ScrollView {
            // Three actions and two lines of copy is more than a screen holds.
            // The spacing is what buys "I'm okay" its place just under the fold
            // rather than a scroll away from it.
            VStack(spacing: 6) {
                SlideIn(index: 0, replay: replay) {
                    OtterAnimationView(clip: level.clip, size: Metrics.otterSize)
                        .overlay(Circle().stroke(Palette.card, lineWidth: 2))
                }
                .padding(.top, -8)
                .id("top")

                SlideIn(index: 1, replay: replay) {
                    Text("A wave may be building.")
                        .font(WaveFont.title)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SlideIn(index: 2, replay: replay) {
                    Text("You don't have to act on it. It passes.")
                        .font(WaveFont.body)
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SlideIn(index: 3, replay: replay) {
                    PillButton(title: "Do an activity", symbol: "water.waves", style: .orange) {
                        store.open(.activity(afterLogging: false))
                    }
                }

                SlideIn(index: 4, replay: replay) {
                    PillButton(title: "Log a craving", symbol: "plus", style: .ink) {
                        store.open(.log)
                    }
                }

                SlideIn(index: 5, replay: replay) {
                    // Dismissing the wave is an answer, not a shrug — it ends
                    // the alert and puts the user back on Home.
                    PillButton(title: "I'm okay", style: .quiet) {
                        Haptics.tap()
                        store.goHome()
                    }
                }
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.bottom, 10)
        }
        .waveScreen()
        // The alert is built only when it fires, so appearing and arriving are
        // now the same event — the entrance and the haptic both hang off it.
        // Flows are presented at the root (see ContentView), so anything
        // started from here ends on Home, which is what resolving the alert
        // means, and it gets there in one move.
        .onAppear {
            replay &+= 1
            // A real wave would arrive as a tap on the wrist.
            Haptics.waveBuilding()
        }
    }
}

#Preview {
    WaveAlertView().environmentObject(WaveStore())
}
