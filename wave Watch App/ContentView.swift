//
//  ContentView.swift
//  wave Watch App
//
//  One page, not five. Home is where you live; the wave alert is what finds
//  you. Logging and exercises are flows you enter and leave, not places — they
//  need the whole screen while they're running.
//
//  The alert used to be a second page of a vertical TabView, which meant it
//  could be swiped to. That was wrong: a wave you can go and look at is not a
//  wave. It only means anything arriving unasked, so it is no longer a page at
//  all — it rises over Home when the prediction fires (here, five seconds after
//  the app opens) and there is no gesture that reaches it.
//
//  Both flows are presented here, at the root, rather than by whichever page
//  started them. That is deliberate: logging can hand straight over to an
//  activity, and an activity ends on Home. Presented from a page, that journey
//  would have to unwind through every screen that opened it — the user would
//  watch the exercise close, then the log screen, then arrive. One presentation
//  at the root means the whole flow closes in a single move.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: WaveStore

    @State private var showSplash = true

    var body: some View {
        ZStack {
            HomeView()

            if store.showAlert {
                // Rises from the bottom the way the page used to slide up, so
                // the arrival still reads the same — it just can't be reached
                // by hand any more.
                WaveAlertView()
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .background(Palette.bg)
        // Focus rings and the crown indicator pick this up. It does not reach
        // the status-bar time, which watchOS always draws white — the one part
        // of the screen the cream palette can't reclaim.
        .tint(Palette.orange)
        .fullScreenCover(isPresented: flowPresented) { WaveFlowView() }
        // The splash sits over everything, including the tab bar chrome, and
        // lifts once — see SplashView.
        .overlay {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            guard showSplash else { return }
            if store.splashDone {
                // -noSplash: skip straight to the app.
                showSplash = false
            } else {
                try? await Task.sleep(for: .seconds(SplashView.hold))
                withAnimation(.easeOut(duration: SplashView.fadeOut)) { showSplash = false }
                store.splashDone = true
            }
            // Fakes the craving the demo needs: five seconds after the app is
            // actually on screen the app takes itself to the wave alert.
            store.scheduleDemoCraving()
        }
    }

    /// The cover is open whenever a flow is. Closing it by any route watchOS
    /// offers clears the flow, so the two can't drift apart.
    private var flowPresented: Binding<Bool> {
        Binding(
            get: { store.flow != nil },
            set: { if !$0 { store.flow = nil } }
        )
    }
}

/// Whichever flow is open, swapped in place. Moving from the log to an activity
/// changes this value rather than presenting anything new.
struct WaveFlowView: View {
    @EnvironmentObject private var store: WaveStore

    /// Trails `store.flow`, and never follows it back to nil. Ending a flow
    /// clears the store's value to close the cover; without this the content
    /// would blank for a frame before the cover finished sliding away.
    @State private var shown: WaveFlow?

    var body: some View {
        Group {
            switch shown ?? store.flow {
            case .log:
                LogView()
            case .activity(let afterLogging):
                ExercisesView(afterLogging: afterLogging)
            case nil:
                Color.clear
            }
        }
        .animation(.easeInOut(duration: 0.22), value: shown)
        .onChange(of: store.flow, initial: true) { _, new in
            if let new { shown = new }
        }
    }
}

#Preview {
    ContentView().environmentObject(WaveStore())
}
