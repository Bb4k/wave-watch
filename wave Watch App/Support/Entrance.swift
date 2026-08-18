//
//  Entrance.swift
//  wave Watch App
//
//  A SwiftUI port of the phone's screen-transition.tsx: the "data loading"
//  entrance every screen plays when it gains focus. Same timings, same
//  vocabulary — cards slide in from the left on a stagger, then bars fill,
//  charts wipe, and the dial sweeps once its card has mostly landed.
//
//  Every primitive starts settled, so nothing animates on a re-render. Home
//  plays its entrance exactly once, when the app opens on it — the data filling
//  in is the app arriving, and repeating it every time the user swipes back
//  turns a flourish into a wait. The alert page plays on arrival, because
//  arriving is the whole event there.
//

import SwiftUI

enum Entrance {
    static let slideDuration = 0.35
    static let stagger = 0.06
    static let distance: CGFloat = 24
    static let revealDuration = 0.6
    /// After this long a slid-in card has "mostly landed".
    static let revealBase = 0.30

    /// The delay a bar/chart in the card at `index` should use, so its reveal
    /// starts once that card has arrived. `extra` staggers items within a card.
    static func chartDelay(_ index: Int, _ extra: Double = 0) -> Double {
        Double(index) * stagger + revealBase + extra
    }
}

// MARK: - Replay trigger

/// Plays the entrance once, the first time the page is actually watchable.
private struct OpenEntranceModifier: ViewModifier {
    @Binding var replay: Int

    @EnvironmentObject private var store: WaveStore
    @State private var played = false

    func body(content: Content) -> some View {
        // The page is built well before it is visible — behind the splash, and
        // behind a flow. Playing on `onAppear` spends the entrance where nobody
        // can see it and the app opens on a finished screen. So it waits for
        // the splash to lift, and the flag keeps a re-render from replaying it.
        content.onChange(of: store.splashDone, initial: true) { _, done in
            guard done, !played else { return }
            played = true
            replay &+= 1
        }
    }
}

extension View {
    /// Bumps `replay` once, when the page first opens — and never again.
    func openEntrance(_ replay: Binding<Int>) -> some View {
        modifier(OpenEntranceModifier(replay: replay))
    }
}

/// Replays a settled value back to 0 and forward to 1 on every `replay` bump.
private struct Played: ViewModifier {
    let replay: Int
    let delay: Double
    let curve: Animation
    @Binding var t: Double

    func body(content: Content) -> some View {
        content.onChange(of: replay) { _, _ in
            t = 0
            withAnimation(curve.delay(delay)) { t = 1 }
        }
    }
}

// MARK: - Primitives

/// Slides and fades in from the left, staggered by `index`. Only transform and
/// opacity animate, so the resting layout is identical.
struct SlideIn<Content: View>: View {
    var index: Int
    var replay: Int
    @ViewBuilder var content: Content

    /// Starts settled — see the file header.
    @State private var t: Double = 1

    var body: some View {
        content
            .opacity(t)
            .offset(x: (1 - t) * -Entrance.distance)
            .modifier(
                Played(
                    replay: replay,
                    delay: Double(index) * Entrance.stagger,
                    curve: .easeOut(duration: Entrance.slideDuration),
                    t: $t
                )
            )
    }
}

/// Left-to-right wipe for charts and heatmaps.
struct ChartWipe<Content: View>: View {
    var delay: Double
    var replay: Int
    @ViewBuilder var content: Content

    @State private var t: Double = 1

    var body: some View {
        content
            .mask(alignment: .leading) {
                // Scaled rather than measured, so nothing reflows as it opens.
                Rectangle().scaleEffect(x: max(t, 0.0001), anchor: .leading)
            }
            .modifier(
                Played(
                    replay: replay,
                    delay: delay,
                    curve: .easeOut(duration: Entrance.revealDuration),
                    t: $t
                )
            )
    }
}

/// Scale-and-fade entrance for the dial's centrepiece, with a slight overshoot.
struct PopIn<Content: View>: View {
    var delay: Double
    var replay: Int
    @ViewBuilder var content: Content

    @State private var t: Double = 1

    var body: some View {
        content
            .scaleEffect(0.6 + 0.4 * t)
            // Front-loaded so the otter is solid while it's still growing.
            .opacity(min(t * 2.5, 1))
            .modifier(
                Played(
                    replay: replay,
                    delay: delay,
                    curve: .spring(response: 0.5, dampingFraction: 0.62),
                    t: $t
                )
            )
    }
}

/// A pie wedge growing clockwise from 6 o'clock — the mask behind the dial's
/// speedometer-style reveal.
struct SweepMask: Shape {
    var t: Double

    var animatableData: Double {
        get { t }
        set { t = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        // Overshoot the radius so the square's corners are covered too.
        let radius = max(rect.width, rect.height)
        path.move(to: centre)
        path.addArc(
            center: centre,
            radius: radius,
            // 6 o'clock, sweeping clockwise up the left side.
            startAngle: .degrees(90),
            endAngle: .degrees(90 + 360 * t),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
